--
-- scale_images.lua — Pandoc Lua filter to scale embedded images to 50% width
--
function Image(el)
    el.attributes.width = "40%"
    return el
end
