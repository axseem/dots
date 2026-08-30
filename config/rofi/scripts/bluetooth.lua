#!/usr/bin/env lua

local process = require("axseem.process")

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
    local command = { "busctl", "--system" }
    for _, value in ipairs(argv) do
        command[#command + 1] = value
    end
    return process.capture(command, nil, { stderr = "discard" })
end

local function discover_adapter()
    local tree = busctl({ "tree", "org.bluez", "--list" })
    if tree.code ~= 0 then
        return tree.code, nil
    end
    for _, path in ipairs(lines(tree.out)) do
        if path:match("^/org/bluez/hci%d+$") then
            adapter_path = path
            return 0, tree.out
        end
    end
    return 0, tree.out
end

local function property(path, interface, name)
    return busctl({ "get-property", "org.bluez", path, interface, name })
end

local function boolean_property(path, interface, name)
    local result = property(path, interface, name)
    if result.code ~= 0 then
        return nil, result.code
    end
    return trim(result.out) == "b true", 0
end

local function string_property(path, interface, name)
    local result = property(path, interface, name)
    if result.code ~= 0 then
        return nil, result.code
    end
    return trim(result.out):match('^s "(.*)"$'), 0
end

local function device_path(address)
    assert(address:match("^[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]$"), "invalid Bluetooth address")
    return adapter_path .. "/dev_" .. address:gsub(":", "_")
end

local function header(prompt, data)
    io.stdout:write("\0no-custom\x1ftrue\n")
    if prompt then
        io.stdout:write("\0prompt\x1f" .. prompt .. "\n")
    end
    if data then
        io.stdout:write("\0data\x1f" .. data .. "\n")
    end
end

local function row(label, icon, info, metadata)
    io.stdout:write(label)
    if icon then
        io.stdout:write("\0icon\x1f" .. icon)
    end
    if info then
        io.stdout:write("\x1finfo\x1f" .. info)
    end
    if metadata then
        io.stdout:write("\x1fmeta\x1f" .. metadata)
    end
    io.stdout:write("\n")
end

local function bluetoothctl(...)
    local command = { "bluetoothctl" }
    for _, value in ipairs({ ... }) do
        command[#command + 1] = value
    end
    return process.run(command, { stdout = "discard" })
end

local function render_main()
    header("Bluetooth")
    local status, tree = discover_adapter()
    if status ~= 0 then
        return status
    end
    if not adapter_path then
        io.stdout:write("No Bluetooth adapter found\0icon\x1fbluetooth-disabled\x1fnonselectable\x1ftrue\n")
        return 0
    end

    local powered, power_status = boolean_property(adapter_path, "org.bluez.Adapter1", "Powered")
    if power_status ~= 0 then
        return power_status
    end
    if not powered then
        row("Turn Bluetooth on", "bluetooth-disabled", "power-on", "enable power")
        return 0
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
            devices[#devices + 1] = { address = address, alias = alias, state = state }
        end
    end
    table.sort(devices, function(left, right)
        return left.alias < right.alias
    end)

    for _, device in ipairs(devices) do
        local icon = device.state == "connected" and "network-bluetooth-activated" or "network-bluetooth"
        row(
            device.alias .. " (" .. device.state .. ")",
            icon,
            "device\t" .. device.address,
            device.address .. " " .. device.state
        )
    end
    row("Scan for devices", "edit-find", "scan", "discover search")
    row("Turn Bluetooth off", "bluetooth-disabled", "power-off", "disable power")
    return 0
end

local function render_device(address)
    local status = discover_adapter()
    if status ~= 0 or not adapter_path then
        return status ~= 0 and status or 1
    end
    local path = device_path(address)
    local alias = string_property(path, "org.bluez.Device1", "Alias") or address
    local connected, connected_status = boolean_property(path, "org.bluez.Device1", "Connected")
    local paired, paired_status = boolean_property(path, "org.bluez.Device1", "Paired")
    local trusted, trusted_status = boolean_property(path, "org.bluez.Device1", "Trusted")
    if connected_status ~= 0 or paired_status ~= 0 or trusted_status ~= 0 then
        return 1
    end

    header(alias, address)
    row(connected and "Disconnect" or "Connect", "network-bluetooth", connected and "disconnect" or "connect")
    row(paired and "Remove pairing" or "Pair", "emblem-system", paired and "remove" or "pair")
    row(trusted and "Untrust" or "Trust", "security-high", trusted and "untrust" or "trust")
    row("Back", "go-previous", "back")
    return 0
end

local function run_action(action, address)
    if action == "power-on" then
        process.run({ "rfkill", "unblock", "bluetooth" }, { stdout = "discard", stderr = "discard" })
        local status = bluetoothctl("power", "on")
        return status == 0 and render_main() or status
    elseif action == "power-off" then
        local status = bluetoothctl("power", "off")
        return status == 0 and render_main() or status
    elseif action == "scan" then
        local status = bluetoothctl("--timeout", "8", "scan", "on")
        return status == 0 and render_main() or status
    elseif action == "back" then
        return render_main()
    end

    if not address then
        io.stderr:write("Bluetooth device address is missing\n")
        return 2
    end
    if action == "device" then
        return render_device(address)
    end

    local command = ({
        connect = "connect",
        disconnect = "disconnect",
        pair = "pair",
        remove = "remove",
        trust = "trust",
        untrust = "untrust",
    })[action]
    if not command then
        io.stderr:write("unknown Bluetooth action: " .. tostring(action) .. "\n")
        return 2
    end
    local status = bluetoothctl(command, address)
    if status ~= 0 then
        return status
    end
    return command == "remove" and render_main() or render_device(address)
end

local selection = os.getenv("ROFI_INFO") or arg[1]
if not selection then
    os.exit(render_main())
end

local action, embedded_address = selection:match("^([^\t]+)\t?(.*)$")
local address = os.getenv("ROFI_DATA")
if embedded_address and embedded_address ~= "" then
    address = embedded_address
end
os.exit(run_action(action, address))
