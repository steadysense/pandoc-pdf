-- fix-internal-links.lua
--
-- Pandoc's Typst writer generates broken internal links:
--   #link(label("#Heading Text with spaces"))[text]
-- The "#" prefix and non-slug format are not valid Typst label references.
-- Pandoc already adds correct <identifier> labels to headings, so only the
-- link references need to be fixed.
--
-- This filter intercepts internal anchor links and emits correct Typst:
--   #link(label("slug-id"))[Link Text]
-- The anchor is URL-decoded and normalised to a lowercase-hyphenated slug
-- to match pandoc's heading identifier format.

function Link(el)
  local target = el.target

  -- Strip links with empty URLs — #link("") is invalid in Typst
  if target == "" then return el.content end

  if target:sub(1, 1) ~= "#" then return nil end  -- leave external links alone

  local anchor = target:sub(2)

  -- URL-decode %XX sequences (e.g. %20 → space) before normalising
  anchor = anchor:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)

  -- Normalise to slug matching pandoc's heading identifier format:
  -- lowercase, spaces/underscores → hyphens, strip non-alphanumeric except hyphens
  local id = anchor:lower()
    :gsub("[%s_]+", "-")
    :gsub("[^%a%d%-]", "")
    :gsub("%-+", "-")
    :gsub("^%-+", "")
    :gsub("%-+$", "")

  -- Serialise link content as Typst so bold/italic etc. are preserved
  local content_typst = pandoc.write(
    pandoc.Pandoc({ pandoc.Plain(el.content) }), "typst"
  ):match("^%s*(.-)%s*$")

  -- Use context/query to gracefully degrade if the label doesn't exist
  -- (e.g. cross-document links that point to a heading in another file).
  -- If the label is found: render as clickable PDF link.
  -- If not found: render as plain text — no error, no broken PDF.
  return pandoc.RawInline("typst",
    "#context { let _t = query(<" .. id .. ">); " ..
    "if _t.len() > 0 { link(<" .. id .. ">)[" .. content_typst .. "] } " ..
    "else { [" .. content_typst .. "] } }")
end
