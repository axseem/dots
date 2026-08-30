#!/usr/bin/env lua

local stat = require("posix.sys.stat")

local path = assert(arg[1], "secret path is required")
local existing = stat.stat(path)
if existing and existing.st_size > 0 then
    os.exit(0)
end

local random = assert(io.open("/dev/urandom", "rb"))
local bytes = assert(random:read(32))
random:close()
assert(#bytes == 32, "short read from /dev/urandom")

local encoded = {}
for index = 1, #bytes do
    encoded[#encoded + 1] = string.format("%02x", bytes:byte(index))
end

local secret = assert(io.open(path, "wb"))
assert(secret:write("SEARX_SECRET_KEY=" .. table.concat(encoded) .. "\n"))
assert(secret:close())
assert(stat.chmod(path, tonumber("600", 8)))
