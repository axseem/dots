#!/usr/bin/env lua

-- Emoji picker backed by the extracted emoji dataset. anyrun's stdin plugin
-- returns the selected row, and the glyph is the first token.
local process = require("axseem.process")
local picker = require("axseem.picker")

local anyrun = "@anyrun@"
local anyrun_plugin = "@anyrun_plugin@"
local wl_copy = "@wl_copy@"
local data_path = "@emoji_data@"

local lines = {}
local by_label = {}
local file = assert(io.open(data_path, "rb"))
for line in file:lines() do
    local emoji, description = line:match("^(%S+)%s+(.*)$")
    if emoji then
        local label = emoji .. " " .. description
        lines[#lines + 1] = label
        by_label[label] = emoji
    end
end
file:close()

local selection = picker.pick(anyrun, anyrun_plugin, {
    lines = table.concat(lines, "\n") .. "\n",
    max_entries = 12,
})
if not selection then
    os.exit(0)
end
local emoji = by_label[selection]
if not emoji then
    os.exit(0)
end
process.feed({wl_copy}, emoji)
