#!/usr/bin/env lua

-- Attach a terminal to its own grouped session on one shared tmux window
-- pool. Every client keeps a private current window while the windows (the
-- shells) are shared, so terminals do not mirror each other and the phone
-- sees every shell. See config/fish/tmux-autostart.fish for the entry point.
--
-- Modes:
--   (none)   create a window, focus it, then attach
--   phone    attach without creating a window; status line on top
--   save     write a resurrect snapshot (used by the systemd timer)

local process = require("axseem.process")
local stat = require("posix.sys.stat")
local stdlib = require("posix.stdlib")
local unistd = require("posix.unistd")

local tmux = "@tmux@"
local bash = "@bash@"
local resurrectSave = "@resurrectSave@"
local resurrectRestore = "@resurrectRestore@"
local toolPath = "@path@"

local anchorSession = "main"
local footPrefix = "foot-"
local phoneSession = "phone"
local windowPrefix = "s"

-- Home Manager's secureSocket puts the server socket under $XDG_RUNTIME_DIR,
-- but ssh and mosh start non-login shells that never source the session
-- variables; without this the phone would start a second server in /tmp.
local function ensureSocketDirectory()
    local current = os.getenv("TMUX_TMPDIR")
    if current ~= nil and current ~= "" then
        return
    end
    local runtime = os.getenv("XDG_RUNTIME_DIR")
    if runtime == nil or runtime == "" then
        runtime = "/run/user/" .. tostring(unistd.getuid())
    end
    stdlib.setenv("TMUX_TMPDIR", runtime, true)
end

-- The launcher can run from a remote login with a minimal PATH, but tmux
-- starts its server from this environment; give the server the tools the
-- resurrect scripts need.
local function extendPath()
    stdlib.setenv("PATH", toolPath .. ":" .. (os.getenv("PATH") or ""), true)
end

local function run(argv)
    local code = process.run(argv)
    if code ~= 0 then
        error(("%s failed with status %d"):format(table.concat(argv, " "), code))
    end
end

local function capture(argv)
    local result = process.capture(argv, nil, {stderr = "discard"})
    if result.code ~= 0 then
        return nil
    end
    return result.out
end

local function listSessions()
    local output = capture({
        tmux,
        "list-sessions",
        "-F",
        "#{session_name} #{session_attached} #{window_id}",
    })
    local sessions = {}
    for line in (output or ""):gmatch("[^\n]+") do
        local name, attached, windowId = line:match("^(%S+)%s+(%d+)%s+(@%d+)$")
        if name then
            sessions[#sessions + 1] = {
                name = name,
                attached = tonumber(attached),
                windowId = windowId,
            }
        end
    end
    return sessions
end

local function findSession(sessions, name)
    for _, session in ipairs(sessions) do
        if session.name == name then
            return session
        end
    end
    return nil
end

-- Sessions left behind by an earlier client, or recreated by resurrect, have
-- no client and no purpose; their windows stay in the pool either way. This
-- replaces destroy-unattached, which tmux applies immediately to a session
-- that has no clients, i.e. before this launcher can attach.
local function cleanStale(sessions)
    for _, session in ipairs(sessions) do
        local stale = session.attached == 0
            and (session.name:match("^foot%-%d+$") ~= nil or session.name == phoneSession)
        if stale then
            process.run(
                {tmux, "kill-session", "-t", session.name},
                {stdout = "discard", stderr = "discard"}
            )
        end
    end
end

local function pickAnchor(sessions)
    if findSession(sessions, anchorSession) then
        return anchorSession
    end
    if sessions[1] then
        return sessions[1].name
    end
    return nil
end

local function listWindows(anchor)
    local output = capture({
        tmux,
        "list-windows",
        "-t",
        anchor,
        "-F",
        "#{window_id}\t#{window_index}\t#{window_name}",
    })
    local windows = {}
    for line in (output or ""):gmatch("[^\n]+") do
        local id, index, name = line:match("^(@%d+)\t(%d+)\t(.*)$")
        if id then
            windows[#windows + 1] = {id = id, index = index, name = name}
        end
    end
    return windows
end

-- A window is taken while it is the current window of an attached client, so
-- the phone and the laptop never fight over the same shell by accident.
local function takenWindows(sessions)
    local taken = {}
    for _, session in ipairs(sessions) do
        if session.attached > 0 then
            taken[session.windowId] = true
        end
    end
    return taken
end

local function pickFreeWindow(windows, sessions)
    local taken = takenWindows(sessions)

    -- Resume the newest free shell instead of stacking up another window.
    local chosen
    local chosenNumber = -1
    for _, window in ipairs(windows) do
        local number = tonumber(window.name:match("^s(%d+)$"))
        if number and not taken[window.id] and number > chosenNumber then
            chosen = window
            chosenNumber = number
        end
    end
    return chosen
end

local function nextWindowName(windows)
    local highest = 0
    for _, window in ipairs(windows) do
        local number = tonumber(window.name:match("^s(%d+)$"))
        if number and number > highest then
            highest = number
        end
    end
    return windowPrefix .. tostring(highest + 1)
end

-- Called through the per-session client-detached hook: the shell a terminal
-- was showing dies with the terminal, unless another client still views it.
local function release(name)
    if name == nil or name:match("^foot%-%d+$") == nil then
        return
    end

    local sessions = listSessions()
    local session = findSession(sessions, name)
    -- Still attached means another client took the session over; leave both.
    if session == nil or session.attached > 0 then
        return
    end

    if not takenWindows(sessions)[session.windowId] then
        process.run(
            {tmux, "kill-window", "-t", session.windowId},
            {stdout = "discard", stderr = "discard"}
        )
    end
    process.run({tmux, "kill-session", "-t", name}, {stdout = "discard", stderr = "discard"})
end

local function restore(sessions)
    if #sessions > 0 then
        return sessions
    end

    local saveFile = assert(os.getenv("HOME"), "HOME is not set") .. "/.tmux/resurrect/last"
    if stat.stat(saveFile) == nil then
        return sessions
    end

    extendPath()
    local code = process.run({bash, resurrectRestore}, {stdout = "discard", stderr = "discard"})
    if code ~= 0 then
        io.stderr:write("tmux-session: resurrect restore failed; starting fresh\n")
    end
    return listSessions()
end

local function setOption(target, option, value)
    run({tmux, "set-option", "-t", target, option, value})
end

-- The phone gets its own session so the status line stays off on the laptop
-- but the window list is reachable on a small screen.
local function configurePhone(target)
    setOption(target, "status", "on")
    setOption(target, "status-position", "top")
    setOption(target, "status-left", "")
    setOption(target, "status-right", "")
    setOption(target, "window-status-format", "#I:#W")
    setOption(target, "window-status-current-format", "#I:#W")
    setOption(target, "window-status-current-style", "fg=black,bg=white")
end

-- tmux parses the hook command, so the whole shell command must be quoted:
-- unquoted, "release <session>" is parsed as a second tmux command and only
-- the launcher path is executed (in default mode, without a terminal).
local function installHook(name)
    process.run(
        {
            tmux,
            "set-hook",
            "-t",
            name,
            "client-detached",
            ('run-shell -b "%s release %s"'):format(arg[0], name),
        },
        {stdout = "discard", stderr = "discard"}
    )
end

local mode = arg[1]
if mode == "save" then
    ensureSocketDirectory()
    extendPath()
    os.exit(process.run({bash, resurrectSave}, {stdout = "discard", stderr = "discard"}))
elseif mode == "release" then
    ensureSocketDirectory()
    extendPath()
    release(arg[2])
    os.exit(0)
elseif mode ~= nil and mode ~= "phone" then
    io.stderr:write("usage: tmux-session [phone]\n")
    os.exit(2)
end

ensureSocketDirectory()
extendPath()
run({tmux, "start-server"})
local sessions = restore(listSessions())
cleanStale(sessions)
sessions = listSessions()

local target = mode == "phone" and phoneSession or footPrefix .. tostring(unistd.getpid())
if findSession(sessions, target) then
    process.exec({tmux, "attach-session", "-t", target})
end

local anchor = pickAnchor(sessions)
local cwd = assert(unistd.getcwd(), "cannot determine the working directory")
local windowName
local bootstrap = false

if anchor == nil then
    -- Start the pool with the window this client is going to use, so a fresh
    -- server does not leave an extra shell behind. A concurrent launcher may
    -- win the race; then fall back to its pool.
    bootstrap = true
    windowName = windowPrefix .. "1"
    local code = process.run(
        {tmux, "new-session", "-d", "-s", anchorSession, "-n", windowName, "-c", cwd},
        {stdout = "discard", stderr = "discard"}
    )
    if code == 0 then
        anchor = anchorSession
    else
        sessions = listSessions()
        anchor = pickAnchor(sessions)
        bootstrap = false
        if anchor == nil then
            error("cannot create a tmux session")
        end
    end
end

local windows
local reuse
if not bootstrap then
    windows = listWindows(anchor)
    reuse = pickFreeWindow(windows, sessions)
    if reuse == nil then
        windowName = nextWindowName(windows)
    end
end

-- destroy-unattached is deliberately not set here: tmux destroys a session
-- with no clients as soon as the option is applied, before this client can
-- attach. cleanStale above removes abandoned sessions instead.
run({tmux, "new-session", "-d", "-t", anchor, "-s", target})

if mode == "phone" then
    configurePhone(target)
    if reuse ~= nil then
        run({tmux, "select-window", "-t", target .. ":" .. reuse.index})
    end
else
    -- The shell this terminal shows dies with it; the hook runs release()
    -- once the client is really gone. A window the phone views survives.
    installHook(target)
    -- Repair hooks written by older launchers on sessions still attached.
    for _, session in ipairs(sessions) do
        if session.name ~= target and session.name:match("^foot%-%d+$") then
            installHook(session.name)
        end
    end

    if bootstrap then
        run({tmux, "select-window", "-t", target .. ":" .. windowName})
    elseif reuse ~= nil then
        run({tmux, "select-window", "-t", target .. ":" .. reuse.index})
    else
        run({tmux, "new-window", "-t", target, "-n", windowName, "-c", cwd})
    end
end

process.exec({tmux, "attach-session", "-t", target})
