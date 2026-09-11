#!/usr/bin/env lua

local process = require("axseem.process")
local picker = require("axseem.picker")

local fuzzel = "@fuzzel@"
local wl_copy = "@wl_copy@"
local data_path = "@emoji_data@"

local display = {}
local by_display = {}
local file = assert(io.open(data_path, "rb"))
for line in file:lines() do
    local emoji, description = line:match("^(%S+)%s+(.*)$")
    if emoji then
        local label = emoji .. " " .. description
        display[#display + 1] = label
        by_display[label] = emoji
    end
end
file:close()

local selection = picker.pick(fuzzel, {prompt = "Emoji", lines = table.concat(display, "\n") .. "\n"})
if not selection then
    os.exit(0)
end
local emoji = by_display[selection]
if not emoji then
    os.exit(0)
end
process.feed({wl_copy}, emoji)
