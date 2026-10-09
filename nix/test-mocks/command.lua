#!/usr/bin/env lua

-- Mock for the external commands the menu scripts call, plus the anyrun
-- picker. Invoked through PATH symlinks named after the command, so arg[0]
-- selects the behaviour.
local function basename(path)
    return (path:gsub(".*/", ""))
end

local function append_log(name, argv)
    local file = assert(io.open(assert(os.getenv("COMMAND_LOG")), "ab"))
    assert(file:write(name .. "\n"))
    for _, value in ipairs(argv) do
        assert(file:write(value .. "\n"))
    end
    assert(file:close())
end

local function has(argv, wanted)
    for _, value in ipairs(argv) do
        if value == wanted then
            return true
        end
    end
    return false
end

-- Picker mock: consumes the menu on stdin, records it when MENU_INPUT is
-- set, then prints the next queued selection (or MOCK_INPUT/MOCK_SELECTION).
local function anyrun()
    local menu = io.stdin:read("*a")
    if os.getenv("MENU_INPUT") then
        local file = assert(io.open(os.getenv("MENU_INPUT"), "wb"))
        assert(file:write(menu))
        assert(file:close())
    end

    local queue = os.getenv("MOCK_SELECTIONS")
    if queue then
        local file = io.open(queue, "rb")
        if file then
            local contents = file:read("*a")
            file:close()
            local first, rest = contents:match("^([^\n]*)\n?(.*)$")
            local remaining = assert(io.open(queue, "wb"))
            assert(remaining:write(rest or ""))
            assert(remaining:close())
            if first and first ~= "" then
                io.stdout:write(first .. "\n")
                os.exit(0)
            end
        end
    end

    local input = os.getenv("MOCK_INPUT")
    if input and input ~= "" then
        io.stdout:write(input .. "\n")
        os.exit(0)
    end

    local selection = os.getenv("MOCK_SELECTION")
    if selection and selection ~= "" then
        io.stdout:write(selection .. "\n")
        os.exit(0)
    end

    os.exit(1)
end

local name = basename(arg[0])
local argv = {}
for index = 1, #arg do
    argv[#argv + 1] = arg[index]
end

if name == "anyrun" then
    anyrun()
elseif name == "swaylock" or name == "foot" then
    append_log(name, argv)
elseif name == "mkdir" then
    -- no-op in tests
elseif name == "date" then
    io.stdout:write("2026-08-30_12-00-00\n")
elseif name == "grim" then
    io.stdout:write("\137PNG\0fixture")
elseif name == "wl-copy" then
    local file = assert(io.open(assert(os.getenv("CLIPBOARD_OUTPUT")), "wb"))
    assert(file:write(io.stdin:read("*a")))
    assert(file:close())
elseif name == "cliphist" then
    if argv[1] == "list" then
        io.stdout:write("1\tfixture\n")
    elseif argv[1] == "decode" then
        assert(io.stdin:read("*a") == "1\tfixture")
        io.stdout:write("decoded\0clipboard")
    else
        error("unexpected cliphist command: " .. tostring(argv[1]))
    end
elseif name == "nmcli" then
    append_log(name, argv)
    if argv[1] == "-t" then
        if has(argv, "list") then
            -- Deliberately unsorted, with one SSID repeated at two strengths
            -- and enough extra networks to overflow a menu page.
            io.stdout:write(
                "*:reprisabe:30:WPA3\n:HomeWifi:42:WPA2\n:OpenWifi:65:\n:HomeWifi:70:WPA2\n"
            )
            for index = 1, 15 do
                io.stdout:write(
                    ":Extra" .. string.format("%02d", index) .. ":" .. 61 - index * 3 .. ":WPA2\n"
                )
            end
        elseif has(argv, "--active") then
            io.stdout:write("reprisabe:d6c23df2-be6a-4cca-8eb1-f595a47fb1fc:802-11-wireless\n")
        elseif has(argv, "show") then
            io.stdout:write(
                "SavedNet:11111111-2222-3333-4444-555555555555:802-11-wireless\n"
                    .. "Wired:66666666-7777-8888-9999-000000000000:802-3-ethernet\n"
            )
        elseif has(argv, "radio") then
            io.stdout:write("WIFI:enabled\n")
        elseif has(argv, "networking") then
            io.stdout:write("enabled\n")
        end
    end
else
    error("unexpected mock command: " .. name)
end
