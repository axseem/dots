-- Shared helpers for the Lua automation tests. Loaded via `dofile(os.getenv("testHelpers"))`.
local helpers = {}

function helpers.command(name)
    local value = assert(os.getenv(name), "missing test command: " .. name)
    return value
end

function helpers.write_file(path, value)
    local file = assert(io.open(path, "wb"))
    assert(file:write(value))
    assert(file:close())
end

function helpers.read_file(path)
    local file = assert(io.open(path, "rb"))
    local value = assert(file:read("*a"))
    file:close()
    return value
end

return helpers
