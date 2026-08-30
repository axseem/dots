#!/usr/bin/env lua

local process = require("axseem.process")
local argv = { assert(os.getenv("ALEJANDRA"), "ALEJANDRA is not set"), "--quiet" }
if #arg == 0 then
    argv[#argv + 1] = "."
else
    for index = 1, #arg do
        argv[#argv + 1] = arg[index]
    end
end
process.exec(argv)
