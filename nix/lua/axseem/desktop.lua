-- Minimal Desktop Entry scanner for the combined launcher. Reads the
-- application databases from XDG_DATA_HOME and XDG_DATA_DIRS, ignoring
-- localized keys, hidden entries and actions.
local dirent = require("posix.dirent")

local desktop = {}

local function split(value, separator)
    local parts = {}
    for part in (value .. separator):gmatch("(.-)" .. separator) do
        parts[#parts + 1] = part
    end
    return parts
end

local function contains(values, wanted)
    for _, value in ipairs(values) do
        if value == wanted then
            return true
        end
    end
    return false
end

local function parse_file(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end

    local entry = {}
    local in_entry = false
    for line in file:lines() do
        if line:match("^%[") then
            if in_entry then
                break
            end
            in_entry = line == "[Desktop Entry]"
        elseif in_entry then
            local key, value = line:match("^([%w%-]+)=(.*)$")
            if key then
                entry[key] = value
            end
        end
    end
    file:close()

    if entry.Type ~= "Application" or entry.NoDisplay == "true" or entry.Hidden == "true" then
        return nil
    end
    local current_desktop = os.getenv("XDG_CURRENT_DESKTOP")
    if current_desktop and current_desktop ~= "" then
        if entry.OnlyShowIn and not contains(split(entry.OnlyShowIn, ";"), current_desktop) then
            return nil
        end
        if entry.NotShowIn and contains(split(entry.NotShowIn, ";"), current_desktop) then
            return nil
        end
    end
    if not entry.Name or not entry.Exec then
        return nil
    end

    return entry
end

local function tokenize(command)
    local argv = {}
    local current = ""
    local started = false
    local index = 1
    while index <= #command do
        local char = command:sub(index, index)
        if char == "\\" and index < #command then
            index = index + 1
            current = current .. command:sub(index, index)
            started = true
        elseif char == '"' then
            started = true
        elseif char == " " or char == "\t" then
            if started then
                argv[#argv + 1] = current
                current = ""
                started = false
            end
        else
            current = current .. char
            started = true
        end
        index = index + 1
    end
    if started then
        argv[#argv + 1] = current
    end
    return argv
end

local function exec_argv(exec)
    local argv = {}
    for _, token in ipairs(tokenize(exec)) do
        local cleaned = token:gsub("%%%%", "\1"):gsub("%%[fFuUdDnNickvm]", ""):gsub("\1", "%%")
        if cleaned ~= "" then
            argv[#argv + 1] = cleaned
        end
    end
    return argv
end

function desktop.entries()
    local directories = {}
    local data_home = os.getenv("XDG_DATA_HOME")
    if not data_home or data_home == "" then
        data_home = assert(os.getenv("HOME"), "HOME is not set") .. "/.local/share"
    end
    directories[#directories + 1] = data_home .. "/applications"
    for _, directory in ipairs(split(os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share", ":")) do
        if directory ~= "" then
            directories[#directories + 1] = directory .. "/applications"
        end
    end

    local entries = {}
    local seen = {}
    for _, directory in ipairs(directories) do
        local ok, names = pcall(dirent.dir, directory)
        if ok and names then
            for _, name in ipairs(names) do
                if name:match("%.desktop$") and not seen[name] then
                    seen[name] = true
                    local entry = parse_file(directory .. "/" .. name)
                    if entry then
                        entries[#entries + 1] = {
                            name = entry.Name,
                            icon = entry.Icon,
                            argv = exec_argv(entry.Exec),
                            terminal = entry.Terminal == "true",
                        }
                    end
                end
            end
        end
    end
    table.sort(entries, function(left, right)
        return left.name < right.name
    end)
    return entries
end

return desktop
