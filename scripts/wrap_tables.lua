--
-- wrap_tables.lua — Force wrapping, balanced column widths for PDF/DOCX.
--
-- Pandoc pipe tables take relative widths from the dash row. Short
-- separators used to become non-wrapping `l` columns. Very long padded
-- separators (common after markdown formatters) make the first column
-- tiny, so words overflow into the next cell. This filter always assigns
-- wrapping widths that fit the page.
--

local function default_widths(n)
    -- Leave a little room for tabcolsep. First column is usually a label,
    -- but must still be wide enough for phrases like "Current Similarity Score".
    if n == 2 then
        return {0.46, 0.50}
    elseif n == 3 then
        return {0.28, 0.34, 0.34}
    elseif n == 4 then
        return {0.22, 0.24, 0.24, 0.26}
    end
    local w = 0.96 / n
    local widths = {}
    for i = 1, n do
        widths[i] = w
    end
    return widths
end

function Table(tbl)
    local n = #tbl.colspecs
    if n == 0 then
        return tbl
    end

    local widths = default_widths(n)
    for i, spec in ipairs(tbl.colspecs) do
        tbl.colspecs[i] = {spec[1], widths[i]}
    end
    return tbl
end
