#!/usr/bin/env lua

-- Mock tmux for the tmux-session automation test. Each invocation is appended
-- to $TMUX_MOCK_LOG (argv separated by tabs); server state is scripted by the
-- test through files:
--   TMUX_MOCK_SESSIONS - "name attached" lines returned by list-sessions
--   TMUX_MOCK_WINDOWS  - window names returned by list-windows
local function read(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local value = file:read("*a")
    file:close()
    return value
end

local function write(path, value)
    local file = assert(io.open(path, "wb"))
    assert(file:write(value))
    assert(file:close())
end

local function log(argv)
    local path = os.getenv("TMUX_MOCK_LOG")
    if not path then
        return
    end
    local file = assert(io.open(path, "ab"))
    for index, value in ipairs(argv) do
        assert(file:write(value))
        assert(file:write(index == #argv and "\n" or "\t"))
    end
    assert(file:close())
end

local argv = {}
for index = 1, #arg do
    argv[#argv + 1] = arg[index]
end
log(argv)

local command = argv[1]

if command == "start-server" then
    os.exit(0)
elseif command == "list-sessions" then
    local sessions = read(assert(os.getenv("TMUX_MOCK_SESSIONS")))
    if sessions == nil then
        os.exit(1)
    end
    io.stdout:write(sessions)
    os.exit(0)
elseif command == "list-windows" then
    local windows = read(assert(os.getenv("TMUX_MOCK_WINDOWS")))
    if windows == nil then
        os.exit(1)
    end
    io.stdout:write(windows)
    os.exit(0)
elseif command == "kill-session" then
    -- Keep later list-sessions calls coherent with the kill.
    local target = argv[3]
    local sessions = read(assert(os.getenv("TMUX_MOCK_SESSIONS")))
    if sessions then
        local kept = {}
        for line in sessions:gmatch("[^\n]+") do
            if line:match("^(%S+)") ~= target then
                kept[#kept + 1] = line
            end
        end
        local suffix = #kept > 0 and "\n" or ""
        write(assert(os.getenv("TMUX_MOCK_SESSIONS")), table.concat(kept, "\n") .. suffix)
    end
    os.exit(0)
else
    -- new-session, new-window, set-option, select-window, attach-session
    os.exit(0)
end
