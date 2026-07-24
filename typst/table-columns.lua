-- table-columns.lua  (Pandoc 3.x / Typst writer)
--
-- Assigns smart column widths to every Pandoc Table node.
--
-- FIXED columns (short, non-wrappable data like dates, codes, short labels):
--   Width based on the longest DATA CELL only (not header), so headers are
--   allowed to wrap. This keeps date/code columns compact.
--
-- FLEX columns (descriptive text):
--   Get fr units, normalised so the ratio between narrowest and widest
--   flex col is at most MAX_FR_RATIO.
--
-- For tables with many columns (>= WIDE_TABLE_COLS), font size is reduced
-- automatically via a Typst set rule wrapping the table.

local FIXED_CHAR_LIMIT = 20   -- data-cell chars; ≤ this → fixed col
local CHARS_PER_CM     = 5.8  -- Arial/Liberation Sans 9pt
local FIXED_PAD_CM     = 0.3  -- padding added to fixed col width
local MIN_FIXED_CM     = 1.4  -- floor for fixed col width
local MIN_FR           = 1.0  -- floor fr weight
local MAX_FR           = 3.0  -- ceiling fr weight (after normalisation)
local WIDE_TABLE_COLS  = 6    -- tables with >= this many cols get smaller font
local WIDE_FONT_SIZE   = "8pt" -- font size for wide tables


-- ── text extraction ──────────────────────────────────────────────────────────
local function str(el)
  if el == nil then return "" end
  local t = type(el)
  if t == "string" then return el end
  if t ~= "table" and t ~= "userdata" then return "" end
  local tag = el.t
  if tag == "Str"   then return el.text or "" end
  if tag == "Space" or tag == "SoftBreak" or tag == "LineBreak" then return " " end
  if tag == "Code"  or tag == "Math"  then return el.text or "" end
  if el.content then
    local p = {}
    for _, v in ipairs(el.content) do p[#p+1] = str(v) end
    return table.concat(p)
  end
  local p = {}
  for _, v in ipairs(el) do p[#p+1] = str(v) end
  return table.concat(p)
end

local function cell_str(cell)
  local p = {}
  for _, block in ipairs(cell.content) do p[#p+1] = str(block) end
  return table.concat(p, " ")
end

local function max_word_len(s)
  local m = 0
  for w in s:gmatch("[^%s,;:/%(%)%%&]+") do
    if #w > m then m = #w end
  end
  return m
end


-- ── collect rows ─────────────────────────────────────────────────────────────
local function collect_rows(tbl)
  local head_rows = {}
  local body_rows = {}
  if tbl.head and tbl.head.rows then
    for _, r in ipairs(tbl.head.rows) do head_rows[#head_rows+1] = r.cells end
  end
  if tbl.bodies then
    for _, body in ipairs(tbl.bodies) do
      for _, r in ipairs(body.body) do body_rows[#body_rows+1] = r.cells end
    end
  end
  return head_rows, body_rows
end


-- ── measure a column across a given set of rows ──────────────────────────────
local function measure_col(rows, ci)
  local max_len = 0
  local max_wrd = 0
  for _, row in ipairs(rows) do
    local cell = row[ci]
    if cell then
      local s = cell_str(cell)
      if #s > max_len then max_len = #s end
      local w = max_word_len(s)
      if w > max_wrd then max_wrd = w end
    end
  end
  return max_len, max_wrd
end


-- ── br normaliser: replace HTML <br /> RawInlines with real LineBreaks ──────
-- pandoc.write(..., "typst") silently drops RawInline html elements, so we
-- must convert them in the AST before serialising.
local function normalise_br(blocks)
  return pandoc.walk_block(
    pandoc.Div(blocks),
    {
      RawInline = function(el)
        if el.format == "html" and el.text:match("^<br") then
          return pandoc.LineBreak()
        end
      end
    }
  ).content
end

-- ── overflow guard: insert zero-width breaks into over-long tokens ───────────
-- The template's show-rules add break opportunities after _ - ( ), which covers
-- most long strings (file names, UDIs). But a token with NONE of those (e.g. a
-- long hash, an unbroken code, a very long compound word) still can't wrap and
-- overflows its cell. This is the generic fallback: given a column's character
-- capacity `cap`, split any word longer than `cap` with U+200B zero-width spaces
-- so Typst can wrap it. Zero-width space is invisible and copy-paste-safe, and
-- only ADDS break points — Typst still fills each line greedily.
local ZWS = utf8.char(0x200B)

-- Longest run of characters with NO break opportunity the template's show-rules
-- can already use. Those rules break after _ - ) / and before ( — so a run ends
-- at any of those. If this longest run already fits the column, the show-rules
-- handle wrapping on their own (giving nice, semantically-aligned breaks) and we
-- leave the word untouched. Only a run that genuinely can't fit needs help.
local function longest_unbreakable(word)
  local codes = {}
  for _, cp in utf8.codes(word) do codes[#codes + 1] = cp end
  local maxrun, run = 0, 0
  for i = 1, #codes do
    run = run + 1
    if run > maxrun then maxrun = run end
    local c   = utf8.char(codes[i])
    local nxt = codes[i + 1] and utf8.char(codes[i + 1]) or ""
    if c:match("[_%-%)/]") or nxt == "(" then run = 0 end  -- break opportunity here
  end
  return maxrun
end

-- Insert a ZWS every `cap` codepoints inside a single whitespace-free word.
-- Fallback only: no-op unless the word's longest unbreakable run exceeds `cap`,
-- so ordinary UDIs / file names keep breaking at their ( ) _ - boundaries.
local function chunk_word(word, cap)
  local n = utf8.len(word)
  if not n or n <= cap then return word end             -- fits, or invalid UTF-8
  if longest_unbreakable(word) <= cap then return word end  -- show-rules suffice
  local out, count = {}, 0
  for _, cp in utf8.codes(word) do
    out[#out + 1] = utf8.char(cp)
    count = count + 1
    if count % cap == 0 and count < n then out[#out + 1] = ZWS end
  end
  return table.concat(out)
end

-- Walk a cell's blocks and chunk every Str whose text exceeds `cap`.
-- (In the Pandoc AST a Str is a maximal run of non-space characters, i.e. one
-- word, so chunking Str text directly is safe.)
local function chunk_blocks(blocks, cap)
  if not cap or cap <= 0 then return blocks end
  return pandoc.walk_block(pandoc.Div(blocks), {
    Str = function(el)
      local t = chunk_word(el.text, cap)
      if t ~= el.text then return pandoc.Str(t) end
    end
  }).content
end

-- ── cell → Typst source ──────────────────────────────────────────────────────
local function cell_to_typst(cell, cap)
  local blocks = chunk_blocks(normalise_br(cell.content), cap)
  -- Strip trailing LineBreaks from Para/Plain blocks before serialising.
  -- A trailing LineBreak becomes "\" in Typst output; when immediately
  -- followed by the cell's closing "]", Typst reads "\]" as an escaped
  -- literal "]" instead of a closing delimiter, leaving the cell unclosed.
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      local inlines = block.content
      while #inlines > 0 and inlines[#inlines].t == "LineBreak" do
        inlines[#inlines] = nil
      end
    end
  end
  local s = pandoc.write(pandoc.Pandoc(blocks), "typst")
  s = s:match("^%s*(.-)%s*$")                    -- trim surrounding whitespace
  if s:sub(-1) == "\\" then s = s:sub(1, -2) end  -- safety: drop residual trailing backslash
  return s
end


-- ── main ─────────────────────────────────────────────────────────────────────
function Table(tbl)
  local ncols = #tbl.colspecs
  if ncols == 0 then return nil end

  local head_rows, body_rows = collect_rows(tbl)
  local all_rows_combined = {}
  for _, r in ipairs(head_rows) do all_rows_combined[#all_rows_combined+1] = r end
  for _, r in ipairs(body_rows) do all_rows_combined[#all_rows_combined+1] = r end

  -- Classify columns: use ONLY body rows for FIXED/FLEX decision
  -- so long header words don't inflate fixed-column widths.
  local specs   = {}
  local flex_ci = {}

  for ci = 1, ncols do
    -- Measure body rows for classification (data drives width)
    local data_len, data_wrd = measure_col(body_rows, ci)
    -- Also measure head for flex weight estimation
    local all_len, _         = measure_col(all_rows_combined, ci)

    if data_len <= FIXED_CHAR_LIMIT then
      -- FIXED: base width on the longest data word + small padding
      local chars = math.max(data_wrd, math.ceil(data_len * 0.7))
      local cm    = math.max(MIN_FIXED_CM, chars / CHARS_PER_CM + FIXED_PAD_CM)
      cm = math.floor(cm * 10 + 0.5) / 10
      specs[ci] = { kind = "fixed", cm = cm, val = string.format("%.1fcm", cm) }
    else
      -- FLEX: weight based on longest content anywhere (head + body)
      local w = math.max(MIN_FR, all_len / 40)
      specs[ci] = { kind = "flex", raw = w }
      flex_ci[#flex_ci+1] = ci
    end
  end

  -- Safety net: if every column ended up FIXED the table uses only absolute cm
  -- widths and won't expand to the available page width.  This happens when all
  -- body rows are empty (template / form tables).  Fall back to equal 1fr so
  -- the table always stretches to 100%.
  if #flex_ci == 0 then
    for ci = 1, ncols do
      specs[ci] = { kind = "flex", raw = 1.0 }
      flex_ci[#flex_ci+1] = ci
    end
  end

  -- Normalise flex: map [min_raw … max_raw] → [MIN_FR … MAX_FR]
  if #flex_ci > 0 then
    local raw_min, raw_max = math.huge, 0
    for _, ci in ipairs(flex_ci) do
      if specs[ci].raw < raw_min then raw_min = specs[ci].raw end
      if specs[ci].raw > raw_max then raw_max = specs[ci].raw end
    end
    for _, ci in ipairs(flex_ci) do
      local norm
      if raw_max == raw_min then
        norm = (MIN_FR + MAX_FR) / 2
      else
        -- linear interpolation from raw into [MIN_FR, MAX_FR]
        norm = MIN_FR + (specs[ci].raw - raw_min) / (raw_max - raw_min) * (MAX_FR - MIN_FR)
      end
      norm = math.floor(norm * 10 + 0.5) / 10
      specs[ci].fr  = norm
      specs[ci].val = string.format("%.1ffr", norm)
    end
  end

  -- Build columns argument
  local parts = {}
  for ci = 1, ncols do parts[ci] = specs[ci].val end
  local col_arg = "(" .. table.concat(parts, ", ") .. ")"

  -- Estimate each column's character capacity, so cell_to_typst can pre-break
  -- any token that would overflow. Widths are approximate — we err on the small
  -- side (SAFETY < 1) so we break a touch early rather than let text run out.
  --   Page text width  = A4 210mm − left 25mm − right 15mm = 170mm = 17.0cm
  --   Per-column inset  = 5pt each side (set in the emitted #table below) ≈ 0.35cm
  --   Chars per cm      = 5.8 at 9pt body; wide tables render at 8pt → ~6.6
  local PAGE_TEXT_WIDTH_CM = 17.0
  local INSET_CM           = 0.35
  local SAFETY             = 0.9
  local MIN_CAP            = 6
  local cpc = (ncols >= WIDE_TABLE_COLS) and 6.6 or CHARS_PER_CM

  local fixed_total, sum_fr = 0, 0
  for ci = 1, ncols do
    if specs[ci].kind == "fixed" then fixed_total = fixed_total + specs[ci].cm
    else                              sum_fr      = sum_fr      + (specs[ci].fr or 0) end
  end
  local flex_avail = PAGE_TEXT_WIDTH_CM - fixed_total - ncols * INSET_CM
  if flex_avail < 2.0 then flex_avail = 2.0 end

  local caps = {}
  for ci = 1, ncols do
    local width_cm
    if specs[ci].kind == "fixed" then
      width_cm = specs[ci].cm - INSET_CM
    elseif sum_fr > 0 then
      width_cm = flex_avail * specs[ci].fr / sum_fr
    else
      width_cm = flex_avail
    end
    local cap = math.floor(width_cm * cpc * SAFETY)
    caps[ci] = (cap < MIN_CAP) and MIN_CAP or cap
  end

  -- Serialise cells
  local lines = {}
  local function add_cells(cells)
    for ci, cell in ipairs(cells) do
      lines[#lines+1] = "  [" .. cell_to_typst(cell, caps[ci]) .. "]"
    end
  end
  for _, r in ipairs(head_rows) do add_cells(r) end
  for _, r in ipairs(body_rows) do add_cells(r) end

  -- For wide tables, wrap in a smaller font size
  local font_override = ""
  if ncols >= WIDE_TABLE_COLS then
    font_override = "#set text(size: " .. WIDE_FONT_SIZE .. ")\n"
  end

  local src = "#block(width: 100%)[\n"
    .. "#set par(justify: true)\n"
    .. font_override
    .. "#table(\n"
    .. "  columns: " .. col_arg .. ",\n"
    .. "  inset: (x: 5pt, y: 4pt),\n"
    .. table.concat(lines, ",\n") .. ",\n"
    .. ")\n"
    .. "]"

  return pandoc.RawBlock("typst", src)
end
