#!/usr/bin/env lua

local process = require("axseem.process")
local alejandra = "@alejandra@"
if alejandra:sub(1, 1) == "@" then
    alejandra = assert(os.getenv("ALEJANDRA"), "ALEJANDRA is not set")
end
local argv = { alejandra, "--quiet" }
if #arg == 0 then
    argv[#argv + 1] = "."
else
    for index = 1, #arg do
        argv[#argv + 1] = arg[index]
    end
end
process.exec(argv)
