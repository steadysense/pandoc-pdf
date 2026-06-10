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

-- ── cell → Typst source ──────────────────────────────────────────────────────
local function cell_to_typst(cell)
  local blocks = normalise_br(cell.content)
  local s = pandoc.write(pandoc.Pandoc(blocks), "typst")
  return s:match("^%s*(.-)%s*$")
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
      specs[ci] = { kind = "fixed", val = string.format("%.1fcm", cm) }
    else
      -- FLEX: weight based on longest content anywhere (head + body)
      local w = math.max(MIN_FR, all_len / 40)
      specs[ci] = { kind = "flex", raw = w }
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
      specs[ci].val = string.format("%.1ffr", norm)
    end
  end

  -- Build columns argument
  local parts = {}
  for ci = 1, ncols do parts[ci] = specs[ci].val end
  local col_arg = "(" .. table.concat(parts, ", ") .. ")"

  -- Serialise cells
  local lines = {}
  local function add_cells(cells)
    for _, cell in ipairs(cells) do
      lines[#lines+1] = "  [" .. cell_to_typst(cell) .. "]"
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
