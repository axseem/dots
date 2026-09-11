#!/usr/bin/env lua

local process = require("axseem.process")
local picker = require("axseem.picker")

local fuzzel = "@fuzzel@"

local adapter_path

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lines(value)
    local result = {}
    for line in (value .. "\n"):gmatch("(.-)\n") do
        result[#result + 1] = line
    end
    return result
end

local function busctl(argv)
    local command = {"busctl", "--system"}
    for _, value in ipairs(argv) do
        command[#command + 1] = value
    end
    return process.capture(command, nil, {stderr = "discard"})
end

local function discover_adapter()
    local tree = busctl({"tree", "org.bluez", "--list"})
    if tree.code ~= 0 then
        return nil
    end
    for _, path in ipairs(lines(tree.out)) do
        if path:match("^/org/bluez/hci%d+$") then
            adapter_path = path
            break
        end
    end
    return tree.out
end

local function property(path, interface, name)
    return busctl({"get-property", "org.bluez", path, interface, name})
end

local function boolean_property(path, interface, name)
    local result = property(path, interface, name)
    if result.code ~= 0 then
        return nil
    end
    return trim(result.out) == "b true"
end

local function string_property(path, interface, name)
    local result = property(path, interface, name)
    if result.code ~= 0 then
        return nil
    end
    return trim(result.out):match('^s "(.*)"$')
end

local function device_path(address)
    assert(address:match("^[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]$"), "invalid Bluetooth address")
    return adapter_path .. "/dev_" .. address:gsub(":", "_")
end

local function bluetoothctl(...)
    local command = {"bluetoothctl"}
    for _, value in ipairs({...}) do
        command[#command + 1] = value
    end
    return process.run(command, {stdout = "discard"})
end

local function pick(prompt, entries)
    local prompts = {}
    local by_label = {}
    for _, entry in ipairs(entries) do
        local line = entry.label
        if entry.icon then
            line = line .. "\0icon\x1f" .. entry.icon
        end
        prompts[#prompts + 1] = line
        by_label[entry.label] = entry
    end
    local selection = picker.pick(fuzzel, {prompt = prompt, lines = table.concat(prompts, "\n") .. "\n"})
    if not selection then
        return nil
    end
    return by_label[selection]
end

local function main_entries(tree)
    if not adapter_path then
        io.stderr:write("No Bluetooth adapter found\n")
        return nil
    end

    local powered = boolean_property(adapter_path, "org.bluez.Adapter1", "Powered")
    if powered == nil then
        return nil
    end
    if not powered then
        return {{label = "Turn Bluetooth on", icon = "bluetooth-disabled", value = {kind = "power-on"}}}
    end

    local devices = {}
    for _, path in ipairs(lines(tree)) do
        local encoded = path:match("^" .. adapter_path .. "/dev_([%x_]+)$")
        if encoded then
            local address = encoded:gsub("_", ":")
            local alias = string_property(path, "org.bluez.Device1", "Alias") or address
            local connected = boolean_property(path, "org.bluez.Device1", "Connected")
            local paired = boolean_property(path, "org.bluez.Device1", "Paired")
            local state = connected and "connected" or paired and "paired" or "available"
            devices[#devices + 1] = {address = address, alias = alias, state = state}
        end
    end
    table.sort(devices, function(left, right)
        return left.alias < right.alias
    end)

    local entries = {}
    local used = {}
    for _, device in ipairs(devices) do
        local label = device.alias .. " (" .. device.state .. ")"
        if used[label] then
            label = label .. " " .. device.address
        end
        used[label] = true
        local icon = device.state == "connected" and "network-bluetooth-activated" or "network-bluetooth"
        entries[#entries + 1] = {
            label = label,
            icon = icon,
            value = {kind = "device", address = device.address},
        }
    end
    entries[#entries + 1] = {label = "Scan for devices", icon = "edit-find", value = {kind = "scan"}}
    entries[#entries + 1] = {label = "Turn Bluetooth off", icon = "bluetooth-disabled", value = {kind = "power-off"}}
    return entries
end

local function device_entries(address)
    local path = device_path(address)
    local connected = boolean_property(path, "org.bluez.Device1", "Connected")
    local paired = boolean_property(path, "org.bluez.Device1", "Paired")
    local trusted = boolean_property(path, "org.bluez.Device1", "Trusted")
    if connected == nil or paired == nil or trusted == nil then
        return nil
    end
    return {
        {
            label = connected and "Disconnect" or "Connect",
            icon = "network-bluetooth",
            value = connected and "disconnect" or "connect",
        },
        {
            label = paired and "Remove pairing" or "Pair",
            icon = "emblem-system",
            value = paired and "remove" or "pair",
        },
        {
            label = trusted and "Untrust" or "Trust",
            icon = "security-high",
            value = trusted and "untrust" or "trust",
        },
    }
end

while true do
    local tree = discover_adapter()
    if not tree then
        io.stderr:write("BlueZ is not available\n")
        os.exit(1)
    end

    local choice = pick("Bluetooth", main_entries(tree))
    if not choice then
        os.exit(0)
    end

    local value = choice.value
    if value.kind == "power-on" then
        process.run({"rfkill", "unblock", "bluetooth"}, {stdout = "discard", stderr = "discard"})
        bluetoothctl("power", "on")
    elseif value.kind == "power-off" then
        bluetoothctl("power", "off")
    elseif value.kind == "scan" then
        bluetoothctl("--timeout", "8", "scan", "on")
    elseif value.kind == "device" then
        local action = pick(choice.label, device_entries(value.address))
        if action then
            bluetoothctl(action.value, value.address)
        end
    end
end
