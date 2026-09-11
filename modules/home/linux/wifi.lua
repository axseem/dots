#!/usr/bin/env lua

-- Wi-Fi menu backed by nmcli. Secured networks that are not saved fall back
-- to an interactive nmcli in a terminal so passwords are never echoed.
local process = require("axseem.process")
local picker = require("axseem.picker")

local anyrun = "@anyrun@"
local anyrun_plugin = "@anyrun_plugin@"
local nmcli = "@nmcli@"
local foot = "@foot@"

local function capture(argv)
    return process.capture(argv, nil, {stderr = "discard"})
end

local function split_escaped(line)
    local fields = {}
    local current = {}
    local escaped = false
    for index = 1, #line do
        local char = line:sub(index, index)
        if escaped then
            current[#current + 1] = char
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif char == ":" then
            fields[#fields + 1] = table.concat(current)
            current = {}
        else
            current[#current + 1] = char
        end
    end
    fields[#fields + 1] = table.concat(current)
    return fields
end

local function visible_networks()
    local result = capture({nmcli, "-t", "-f", "IN-USE,SSID,SECURITY", "device", "wifi", "list", "--rescan", "no"})
    if result.code ~= 0 then
        return {}
    end
    local networks = {}
    local seen = {}
    for line in result.out:gmatch("[^\n]+") do
        local fields = split_escaped(line)
        local ssid = fields[2]
        if ssid and ssid ~= "" and not seen[ssid] then
            seen[ssid] = true
            networks[#networks + 1] = {
                in_use = fields[1] == "*",
                ssid = ssid,
                security = fields[3] or "",
            }
        end
    end
    return networks
end

local function saved_connections()
    local result = capture({nmcli, "-t", "-f", "NAME,TYPE", "connection", "show"})
    if result.code ~= 0 then
        return {}
    end
    local saved = {}
    for line in result.out:gmatch("[^\n]+") do
        local name, kind = line:match("^([^:]+):(.+)$")
        if name and kind == "802-11-wireless" then
            saved[#saved + 1] = name
        end
    end
    return saved
end

local function radio_enabled()
    local result = capture({nmcli, "-t", "-f", "WIFI", "radio"})
    return result.out:match("enabled") ~= nil
end

local function connect(entry)
    if entry.kind == "network" then
        if entry.security ~= "" and entry.security ~= "--" then
            process.detach({foot, "-e", nmcli, "--ask", "device", "wifi", "connect", entry.ssid})
        else
            capture({nmcli, "device", "wifi", "connect", entry.ssid})
        end
    elseif entry.kind == "saved" then
        capture({nmcli, "connection", "up", "id", entry.ssid})
    elseif entry.kind == "radio" then
        capture({nmcli, "radio", "wifi", entry.enabled and "off" or "on"})
    elseif entry.kind == "nmtui" then
        process.detach({foot, "-e", "nmtui"})
    end
end

local entries = {}
local by_label = {}

local function add(label, entry)
    entries[#entries + 1] = label
    by_label[label] = entry
end

for _, network in ipairs(visible_networks()) do
    local suffix = network.in_use and " (connected)" or network.security ~= "" and " (" .. network.security .. ")" or " (open)"
    add(network.ssid .. suffix, {kind = "network", ssid = network.ssid, security = network.security})
end
for _, name in ipairs(saved_connections()) do
    if not by_label[name .. " (saved)"] then
        add(name .. " (saved)", {kind = "saved", ssid = name})
    end
end
local radio = radio_enabled()
add(radio and "Turn Wi-Fi off" or "Turn Wi-Fi on", {kind = "radio", enabled = radio})
add("Open network settings", {kind = "nmtui"})

local selection = picker.pick(anyrun, anyrun_plugin, {lines = table.concat(entries, "\n") .. "\n"})
if not selection then
    os.exit(0)
end
local entry = by_label[selection]
if entry then
    connect(entry)
end
