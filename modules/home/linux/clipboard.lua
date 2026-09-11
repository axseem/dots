#!/usr/bin/env lua

local process = require("axseem.process")
local picker = require("axseem.picker")

local fuzzel = "@fuzzel@"
local cliphist = "@cliphist@"
local wl_copy = "@wl_copy@"

local history = process.capture({cliphist, "list"})
if history.code ~= 0 or history.out == "" then
    os.exit(history.code)
end

local selection = picker.pick(fuzzel, {prompt = "Clipboard", lines = history.out})
if not selection then
    os.exit(0)
end

local decoded = process.capture({cliphist, "decode"}, selection)
if decoded.code ~= 0 then
    os.exit(decoded.code)
end

os.exit(process.feed({wl_copy}, decoded.out))
