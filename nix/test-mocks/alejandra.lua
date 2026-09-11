#!/usr/bin/env lua

local file = assert(io.open(assert(os.getenv("formatterLog")), "wb"))
for index = 1, #arg do assert(file:write(arg[index], "\n")) end
assert(file:close())
