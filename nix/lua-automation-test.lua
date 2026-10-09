local process = require("axseem.process")
local bit = require("bit")
local stat = require("posix.sys.stat")
local stdlib = require("posix.stdlib")

local helpers = dofile(assert(os.getenv("testHelpers")))
local write_file = helpers.write_file
local read_file = helpers.read_file
local command = helpers.command

local sink_path = assert(os.getenv("TMPDIR")) .. "/lua-automation-sink"

if arg[1] == "sink" then
    write_file(sink_path, io.stdin:read("*a"))
    os.exit(0)
elseif arg[1] == "sink-detached" then
    write_file(assert(arg[2]), "detached\n")
    os.exit(0)
elseif arg[1] == "exec" then
    process.exec({ assert(os.getenv("printfCommand")), "%s", "replaced" })
end

assert(process.run({ command("trueCommand") }) == 0)
assert(process.run({ command("falseCommand") }, { stdout = "discard", stderr = "discard" }) == 1)

local result = process.capture({
    command("printfCommand"),
    "%s|%s|%s|%s|%s",
    "space separated",
    "quote'\"",
    "*",
    "-leading",
    "",
})
assert(result.code == 0)
assert(result.out == "space separated|quote'\"|*|-leading|")

local input = string.rep("x\0", 500000)
result = process.capture({ command("catCommand") }, input)
assert(result.code == 0)
assert(result.out == input)

result = process.capture({ command("falseCommand") }, nil, { stderr = "discard" })
assert(result.code == 1)

assert(process.feed({ command("luaCommand"), arg[0], "sink" }, input) == 0)
assert(read_file(sink_path) == input)

result = process.capture({ command("luaCommand"), arg[0], "exec" })
assert(result.code == 0)
assert(result.out == "replaced")

for _, variable in ipairs({
    "actionsScript",
    "clipboardScript",
    "emojiScript",
    "wifiScript",
    "formatterScript",
    "lsnixScript",
    "mimeScript",
    "secretScript",
    "swayidleScript",
    "sxngScript",
    "tmuxSessionScript",
}) do
    assert(loadfile(assert(os.getenv(variable), variable .. " is not set")))
end

local original_path = assert(os.getenv("PATH"))
result = process.capture(
    { command("luaCommand"), assert(os.getenv("lsnixScript")) },
    nil,
    { stderr = "discard" }
)
assert(result.code == 1)
assert(stdlib.setenv("IN_NIX_SHELL", "pure", true))
assert(stdlib.setenv("buildInputs", "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-alpha-1 /nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-beta-2", true))
assert(stdlib.setenv("nativeBuildInputs", "/nix/store/cccccccccccccccccccccccccccccccc-alpha-1", true))
assert(stdlib.setenv("propagatedBuildInputs", "not-a-store-path", true))
result = process.capture({ command("luaCommand"), assert(os.getenv("lsnixScript")) })
assert(result.code == 0)
assert(result.out == "alpha-1\nbeta-2\n")
assert(stdlib.setenv("PATH", original_path, true))

local detached_path = assert(os.getenv("TMPDIR")) .. "/lua-automation-detached"
assert(process.detach({command("luaCommand"), arg[0], "sink-detached", detached_path}) > 0)
local detached = false
for _ = 1, 40 do
    if stat.stat(detached_path) then
        detached = true
        break
    end
    process.run({command("sleepCommand"), "0.1"})
end
assert(detached, "detached process did not run")
assert(read_file(detached_path) == "detached\n")

local root = assert(os.getenv("TMPDIR")) .. "/managed-automation"
assert(stat.mkdir(root, tonumber("700", 8)))
local formatter_log = root .. "/formatter-log"
assert(stdlib.setenv("formatterLog", formatter_log, true))
assert(stdlib.setenv("PATH", assert(os.getenv("runtimeBin")), true))
assert(process.run({ assert(os.getenv("formatterScript")) }) == 0)
assert(read_file(formatter_log) == "--quiet\n.\n")

local mime_types = root .. "/mime-types"
local mime_log = root .. "/mime-log"
write_file(mime_types, "text/plain\nimage/png\ntext/markdown\n")
write_file(mime_log, "")
assert(stdlib.setenv("mimeLog", mime_log, true))
assert(stdlib.setenv("PATH", assert(os.getenv("runtimeBin")), true))
assert(process.run({
    command("luaCommand"),
    assert(os.getenv("mimeScript")),
    mime_types,
    "nvim.desktop",
    assert(os.getenv("mimeMock")),
}) == 0)
assert(read_file(mime_log) == "default\nnvim.desktop\ntext/plain\ndefault\nnvim.desktop\ntext/markdown\n")

local secret_path = root .. "/secret"
assert(process.run({ command("luaCommand"), assert(os.getenv("secretScript")), secret_path }) == 0)
local secret = read_file(secret_path)
assert(secret:match("^SEARX_SECRET_KEY=%x+\n$"))
assert(#secret == 82)
assert(bit.band(assert(stat.stat(secret_path)).st_mode, tonumber("777", 8)) == tonumber("600", 8))
assert(process.run({ command("luaCommand"), assert(os.getenv("secretScript")), secret_path }) == 0)
assert(read_file(secret_path) == secret)

-- tmux-session: every terminal gets a private grouped session over one shared
-- window pool, so clients never mirror each other. Closing a terminal kills
-- the shell it was showing unless another client is viewing it.
local tmux_root = assert(os.getenv("TMPDIR")) .. "/tmux-session-automation"
assert(stat.mkdir(tmux_root, tonumber("700", 8)))
local tmux_home = tmux_root .. "/home"
assert(stat.mkdir(tmux_home, tonumber("700", 8)))
assert(stat.mkdir(tmux_home .. "/.tmux", tonumber("700", 8)))
assert(stat.mkdir(tmux_home .. "/.tmux/resurrect", tonumber("700", 8)))
local tmux_log = tmux_root .. "/log"
local tmux_sessions = tmux_root .. "/sessions"
local tmux_windows = tmux_root .. "/windows"
local resurrect_log = tmux_root .. "/resurrect"
local original_home = assert(os.getenv("HOME"))

local function set_env(name, value)
    assert(stdlib.setenv(name, value, true))
end

local function run_tmux_session(...)
    write_file(tmux_log, "")
    local argv = {command("luaCommand"), assert(os.getenv("tmuxSessionScript"))}
    for _, value in ipairs({...}) do
        argv[#argv + 1] = value
    end
    local result = process.capture(argv, nil, {stderr = "discard"})
    return result.code, read_file(tmux_log)
end

set_env("HOME", tmux_home)
set_env("TMUX_MOCK_LOG", tmux_log)
set_env("TMUX_MOCK_SESSIONS", tmux_sessions)
set_env("TMUX_MOCK_WINDOWS", tmux_windows)
set_env("TMUX_RESURRECT_LOG", resurrect_log)

-- Fresh server: bootstrap main with s1, group a new session on it, attach.
os.remove(tmux_sessions)
os.remove(tmux_home .. "/.tmux/resurrect/last")
write_file(tmux_windows, "")
local code, log = run_tmux_session()
assert(code == 0)
assert(log:match("new%-session\t%-d\t%-s\tmain\t%-n\ts1\t%-c\t"))
assert(log:match("new%-session\t%-d\t%-t\tmain\t%-s\tfoot%-%d+\n"))
-- destroy-unattached would kill the session before this client attaches.
assert(not log:match("destroy%-unattached"))
-- The release command is one quoted shell command; unquoted, tmux parses
-- "release <session>" as a second tmux command.
local hook_target, hook_command =
    log:match('set%-hook\t%-t\t(foot%-%d+)\tclient%-detached\trun%-shell %-b "([^"]+)"\n')
assert(hook_target, "release hook was not installed")
assert(hook_command:find(" release ", 1, true))
assert(hook_command:sub(-#hook_target) == hook_target)
assert(log:match("select%-window\t%-t\tfoot%-%d+:s1\n"))
assert(log:match("attach%-session\t%-t\tfoot%-%d+\n$"))

-- Stale sessions are killed, the newest free window is resumed, and a window
-- another client is viewing is left alone.
write_file(tmux_sessions, "main 0 @2\nfoot-42 0 @2\nphone 1 @4\n")
write_file(tmux_windows, "@2\t1\ts1\n@4\t3\ts3\n")
code, log = run_tmux_session()
assert(code == 0)
assert(log:match("kill%-session\t%-t\tfoot%-42\n"))
assert(not log:match("kill%-session\t%-t\tphone"))
assert(log:match("select%-window\t%-t\tfoot%-%d+:1\n"))
assert(not log:match("new%-window"))

-- When every window is in use, a fresh one is created.
write_file(tmux_sessions, "main 0 @2\nfoot-7 1 @2\nphone 1 @4\n")
write_file(tmux_windows, "@2\t1\ts1\n@4\t3\ts3\n")
code, log = run_tmux_session()
assert(code == 0)
assert(log:match("new%-window\t%-t\tfoot%-%d+\t%-n\ts4\t%-c\t"))
-- Live sessions from older launchers get their hook repaired too.
assert(log:match('set%-hook\t%-t\tfoot%-7\tclient%-detached\trun%-shell %-b "'))
assert(log:match("attach%-session\t%-t\tfoot%-%d+\n$"))

-- Phone mode resumes the newest free window and turns the status line on top.
write_file(tmux_sessions, "main 0 @2\n")
write_file(tmux_windows, "@2\t1\ts1\n")
code, log = run_tmux_session("phone")
assert(code == 0)
assert(log:match("new%-session\t%-d\t%-t\tmain\t%-s\tphone\n"))
assert(log:match("set%-option\t%-t\tphone\tstatus\ton\n"))
assert(log:match("set%-option\t%-t\tphone\tstatus%-position\ttop\n"))
assert(log:match("select%-window\t%-t\tphone:1\n"))
assert(log:match("attach%-session\t%-t\tphone\n$"))
-- The phone session must not reap its window on detach.
assert(not log:match("set%-hook"))
assert(not log:match("new%-window"))

-- A fresh server with a resurrect snapshot restores it, then resumes it.
os.remove(tmux_sessions)
write_file(tmux_home .. "/.tmux/resurrect/last", "snapshot\n")
write_file(resurrect_log, "")
set_env("TMUX_MOCK_SESSIONS_SEED", "main 0 @2\n")
write_file(tmux_windows, "@2\t1\ts1\n")
code, log = run_tmux_session()
assert(code == 0)
assert(read_file(resurrect_log) == "called\n")
assert(not log:match("new%-session\t%-d\t%-s\tmain"))
assert(log:match("select%-window\t%-t\tfoot%-%d+:1\n"))
assert(not log:match("new%-window"))
assert(log:match("attach%-session\t%-t\tfoot%-%d+\n$"))

-- release kills the shell a closed terminal was showing...
write_file(tmux_sessions, "foot-42 0 @5\nphone 1 @7\n")
code, log = run_tmux_session("release", "foot-42")
assert(code == 0)
assert(log:match("kill%-window\t%-t\t@5\n"))
assert(log:match("kill%-session\t%-t\tfoot%-42\n"))

-- ...but a window another client is viewing survives it.
write_file(tmux_sessions, "foot-42 0 @5\nphone 1 @5\n")
code, log = run_tmux_session("release", "foot-42")
assert(code == 0)
assert(not log:match("kill%-window"))
assert(log:match("kill%-session\t%-t\tfoot%-42\n"))

-- release ignores sessions that are not laptop terminals.
write_file(tmux_sessions, "main 0 @5\n")
code, log = run_tmux_session("release", "main")
assert(code == 0)
assert(log == "")

-- Save mode is what the systemd timer runs.
write_file(resurrect_log, "")
code = run_tmux_session("save")
assert(code == 0)
assert(read_file(resurrect_log) == "called\n")

set_env("HOME", original_home)

local output = assert(io.open(assert(os.getenv("out")), "wb"))
assert(output:write("ok\n"))
assert(output:close())
