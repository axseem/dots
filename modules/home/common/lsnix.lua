#!/usr/bin/env lua

if os.getenv("IN_NIX_SHELL") == nil then
    io.stderr:write("Not in a nix shell\n")
    os.exit(1)
end

local seen = {}
local names = {}
for _, variable in ipairs({ "buildInputs", "nativeBuildInputs", "propagatedBuildInputs" }) do
    for entry in (os.getenv(variable) or ""):gmatch("%S+") do
        local hash, name = entry:match("^/nix/store/([a-z0-9]+)%-(.+)$")
        if hash and #hash == 32 and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
end

table.sort(names)
for _, name in ipairs(names) do
    io.stdout:write(name .. "\n")
end
