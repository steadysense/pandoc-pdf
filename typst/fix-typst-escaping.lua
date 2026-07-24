-- fix-typst-escaping.lua
-- Fixes two Pandoc → Typst writer issues:
--
-- 1. Trailing LineBreak inside table cells:
--    Pandoc emits "\]" which Typst reads as an escaped literal "]",
--    leaving the cell bracket unclosed. Strip trailing LineBreaks from
--    every Para/Plain block inside table cells.
--
-- 2. Incorrect digit escaping:
--    Pandoc's Typst writer escapes "9." as "\9." to prevent ordered-list
--    interpretation, but Typst only allows escaping special characters —
--    "\9" is invalid. Replace Str elements matching "N." with RawInline
--    so the writer never touches them.

-- ── Fix 1: trailing line-break in table cells ────────────────────────────────
-- <br /> in table markdown passes as RawInline "html" "<br />".
-- Pandoc's Typst writer renders that as "\" (line-break), so a trailing one
-- becomes "\]" — Typst reads "\]" as an escaped literal "]", leaving the cell
-- bracket unclosed.  Convert html <br> to LineBreak everywhere, then strip
-- any trailing LineBreak from table cell content.

function RawInline(el)
  if el.format == "html" and el.text:match("^<br") then
    return pandoc.LineBreak()
  end
end

-- Pandoc's Typst writer silently DROPS raw LaTeX, so a "\newpage" / "\pagebreak"
-- marker (parsed as a RawBlock of format "tex") produces no break at all.
-- Translate it to a raw Typst pagebreak so the long-standing "\newpage"
-- convention used throughout these documents keeps working, in any document.
function RawBlock(el)
  if (el.format == "tex" or el.format == "latex")
     and (el.text:match("^\\newpage") or el.text:match("^\\pagebreak")) then
    return pandoc.RawBlock("typst", "#pagebreak()")
  end
end

local function strip_trailing_linebreaks(inlines)
  while #inlines > 0 and inlines[#inlines].t == "LineBreak" do
    table.remove(inlines)
  end
  return inlines
end

local function fix_cell_blocks(blocks)
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      block.content = strip_trailing_linebreaks(block.content)
    end
  end
  return blocks
end

function Table(tbl)
  -- Pandoc 3.x table structure: Head, Body list, Foot
  -- Each has .rows; each row has .cells; each cell has .contents (list of blocks)
  local function fix_rows(rows)
    for _, row in ipairs(rows) do
      for _, cell in ipairs(row.cells) do
        cell.contents = fix_cell_blocks(cell.contents)
      end
    end
  end

  fix_rows(tbl.head.rows)
  for _, body in ipairs(tbl.bodies) do
    fix_rows(body.head)
    fix_rows(body.body)
  end
  fix_rows(tbl.foot.rows)
  return tbl
end

-- ── Fix 2: digit-period escaping  ("9." → RawInline instead of "\9.") ────────

function Str(el)
  -- Match strings that are purely digits followed by a period, e.g. "9." "12."
  -- Pandoc's Typst writer incorrectly escapes these as "\9." etc.
  if el.text:match("^%d+%.$") then
    return pandoc.RawInline("typst", el.text)
  end
end
