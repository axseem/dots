#!/usr/bin/env lua

local process = require("axseem.process")

local types_path = assert(arg[1], "MIME types path is required")
local desktop_entry = assert(arg[2], "desktop entry is required")
local xdg_mime = assert(arg[3], "xdg-mime path is required")

local types = assert(io.open(types_path, "rb"))
for mime_type in types:lines() do
    if mime_type:match("^text/") then
        local status = process.run({ xdg_mime, "default", desktop_entry, mime_type })
        if status ~= 0 then
            types:close()
            os.exit(status)
        end
    end
end
types:close()
