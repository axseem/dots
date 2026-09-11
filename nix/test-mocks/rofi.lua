#!/usr/bin/env lua

local process = require("axseem.process")
local argv = { assert(os.getenv("luaCommand")), assert(os.getenv("testFile")), "mock", arg[0]:match("([^/]+)$") }
for index = 1, #arg do argv[#argv + 1] = arg[index] end
process.exec(argv)
