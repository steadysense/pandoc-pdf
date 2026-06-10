-- Remove literal [TOC] placeholders from the document body.
-- The template handles the TOC via #outline(); this marker is redundant.
function Para(el)
  if #el.content == 1 then
    local item = el.content[1]
    if item.t == "Str" and item.text == "[TOC]" then
      return {}
    end
    -- Also handle as a link: [TOC] parsed as Link with empty target
    if item.t == "Link" and pandoc.utils.stringify(item.content) == "TOC" then
      return {}
    end
  end
end
