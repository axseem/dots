#!/usr/bin/env lua

local process = require("axseem.process")

local alejandra = "@alejandra@"
assert(alejandra:sub(1, 1) ~= "@", "alejandra path was not substituted")
local argv = {alejandra, "--quiet"}
if #arg == 0 then
    argv[#argv + 1] = "."
else
    for index = 1, #arg do
        argv[#argv + 1] = arg[index]
    end
end
process.exec(argv)
