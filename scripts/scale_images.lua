--
-- scale_images.lua — Pandoc Lua filter for image widths in DOCX/PDF
-- Screenshots stay compact; rendered Mermaid diagrams stay readable.
--
function Image(el)
    local src = el.src or ""
    if src:match("mermaid%-") or src:match("%.svg$") or src:match("%.emf$") then
        el.attributes.width = "90%"
    else
        el.attributes.width = "40%"
    end
    return el
end
