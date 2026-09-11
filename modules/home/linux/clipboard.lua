#!/usr/bin/env lua

local process = require("axseem.process")
local picker = require("axseem.picker")

local anyrun = "@anyrun@"
local anyrun_plugin = "@anyrun_plugin@"
local cliphist = "@cliphist@"
local wl_copy = "@wl_copy@"

local history = process.capture({cliphist, "list"})
if history.code ~= 0 or history.out == "" then
    os.exit(history.code)
end

local lines = {}
for line in history.out:gmatch("[^\n]+") do
    lines[#lines + 1] = line
end

local selection = picker.pick(anyrun, anyrun_plugin, {
    lines = table.concat(lines, "\n") .. "\n",
    max_entries = 15,
})
if not selection then
    os.exit(0)
end

local decoded = process.capture({cliphist, "decode"}, selection)
if decoded.code ~= 0 then
    os.exit(decoded.code)
end

os.exit(process.feed({wl_copy}, decoded.out))
