#!/usr/bin/env lua

local process = require("axseem.process")
local picker = require("axseem.picker")

local fuzzel = "@fuzzel@"
local qalc = "@qalc@"
local wl_copy = "@wl_copy@"

local expression = picker.pick(fuzzel, {prompt = "= ", lines = ""})
if not expression then
    os.exit(0)
end

local result = process.capture({qalc, "-t", expression}, nil, {stderr = "discard"})
local value = result.out:gsub("^%s+", ""):gsub("%s+$", "")
if result.code ~= 0 or value == "" then
    io.stderr:write("calc: could not evaluate: " .. expression .. "\n")
    os.exit(1)
end

io.stdout:write(value .. "\n")
process.feed({wl_copy}, value)
