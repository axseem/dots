-- Rofi dmenu protocol helpers shared by the rofi scripts.
local rofi = {}

function rofi.trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function rofi.header(prompt, data)
    io.stdout:write("\0no-custom\x1ftrue\n")
    if prompt then
        io.stdout:write("\0prompt\x1f" .. prompt .. "\n")
    end
    if data then
        io.stdout:write("\0data\x1f" .. data .. "\n")
    end
end

function rofi.row(label, icon, info, meta)
    io.stdout:write(label)
    if icon then
        io.stdout:write("\0icon\x1f" .. icon)
    end
    if info then
        io.stdout:write("\x1finfo\x1f" .. info)
    end
    if meta then
        io.stdout:write("\x1fmeta\x1f" .. meta)
    end
    io.stdout:write("\n")
end

return rofi
