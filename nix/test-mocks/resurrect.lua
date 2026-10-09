#!/usr/bin/env lua

-- Stand-in for the resurrect save/restore scripts: records the call and,
-- when the test seeds it, writes the mocked session list that a restore
-- would produce.
local log = os.getenv("TMUX_RESURRECT_LOG")
if log then
    local file = assert(io.open(log, "ab"))
    assert(file:write("called\n"))
    assert(file:close())
end

local seed = os.getenv("TMUX_MOCK_SESSIONS_SEED")
if seed then
    local file = assert(io.open(assert(os.getenv("TMUX_MOCK_SESSIONS")), "wb"))
    assert(file:write(seed))
    assert(file:close())
end
