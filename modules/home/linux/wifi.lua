#!/usr/bin/env lua

-- Wi-Fi menu backed by nmcli: list access points with signal strength,
-- connect to visible or saved networks, disconnect, forget saved networks,
-- rescan, show the password/QR code, and toggle the Wi-Fi radio or all of
-- networking. Secured networks that are not saved fall back to an interactive
-- nmcli in a terminal so passwords are never echoed.
local process = require("axseem.process")
local picker = require("axseem.picker")

local anyrun = "@anyrun@"
local anyrun_plugin = "@anyrun_plugin@"
local nmcli = "@nmcli@"
local foot = "@foot@"

local SIGNAL_BARS = {"▂", "▄", "▆", "█"}

-- anyrun has no scrolling and lays out one fixed 32 px row per match, so a
-- page can only be as tall as the space below the window anchor. The item
-- list is paged instead of truncated.
local PAGE_SIZE = 18

local function capture(argv)
    return process.capture(argv, nil, {stderr = "discard"})
end

-- nmcli -t escapes the field separator as "\:", so fields must be split on
-- unescaped separators only.
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

local function signal_bars(signal)
    local level = math.floor((tonumber(signal) or 0) / 25) + 1
    level = math.max(1, math.min(#SIGNAL_BARS, level))
    local bars = {}
    for index = 1, level do
        bars[#bars + 1] = SIGNAL_BARS[index]
    end
    return table.concat(bars)
end

-- Access points, merged per SSID (a mesh repeats one SSID per band) and
-- sorted with the connected network first, then by signal strength.
local function visible_networks(rescan)
    local result = capture({
        nmcli,
        "-t",
        "-f",
        "IN-USE,SSID,SIGNAL,SECURITY",
        "device",
        "wifi",
        "list",
        "--rescan",
        rescan and "yes" or "no",
    })
    if result.code ~= 0 then
        return {}
    end
    local networks = {}
    local by_ssid = {}
    for line in result.out:gmatch("[^\n]+") do
        local fields = split_escaped(line)
        local ssid = fields[2]
        if ssid and ssid ~= "" then
            local network = by_ssid[ssid]
            if not network then
                network = {in_use = false, ssid = ssid, signal = 0, security = fields[4] or ""}
                by_ssid[ssid] = network
                networks[#networks + 1] = network
            end
            local signal = tonumber(fields[3]) or 0
            if signal > network.signal then
                network.signal = signal
            end
            if fields[1] == "*" then
                network.in_use = true
            end
        end
    end
    table.sort(networks, function(left, right)
        if left.in_use ~= right.in_use then
            return left.in_use
        end
        return left.signal > right.signal
    end)
    return networks
end

local function saved_connections()
    local result = capture({nmcli, "-t", "-f", "NAME,UUID,TYPE", "connection", "show"})
    if result.code ~= 0 then
        return {}
    end
    local saved = {}
    for line in result.out:gmatch("[^\n]+") do
        local fields = split_escaped(line)
        if fields[3] == "802-11-wireless" then
            saved[#saved + 1] = {name = fields[1], uuid = fields[2]}
        end
    end
    return saved
end

local function active_wifi()
    local result = capture({nmcli, "-t", "-f", "NAME,UUID,TYPE", "connection", "show", "--active"})
    if result.code ~= 0 then
        return nil
    end
    for line in result.out:gmatch("[^\n]+") do
        local fields = split_escaped(line)
        if fields[3] == "802-11-wireless" then
            return {name = fields[1], uuid = fields[2]}
        end
    end
    return nil
end

local function radio_enabled()
    local result = capture({nmcli, "-t", "-f", "WIFI", "radio"})
    return result.out:match("enabled") ~= nil
end

local function networking_enabled()
    local result = capture({nmcli, "-t", "networking"})
    return result.out:match("enabled") ~= nil
end

local function network_label(network)
    local security = network.security
    if security == "" or security == "--" then
        security = "open"
    end
    local connected = network.in_use and " (connected)" or ""
    return network.ssid .. "  " .. signal_bars(network.signal) .. "  " .. security .. connected
end

-- Profiles can share a name, so duplicates get a numbered suffix; actions
-- still address profiles by UUID.
local function saved_labels(saved)
    local labels = {}
    local by_label = {}
    local counts = {}
    for _, connection in ipairs(saved) do
        counts[connection.name] = (counts[connection.name] or 0) + 1
        local suffix = counts[connection.name] > 1 and " (saved #" .. counts[connection.name] .. ")" or " (saved)"
        local label = connection.name .. suffix
        labels[#labels + 1] = label
        by_label[label] = connection
    end
    return labels, by_label
end

local function forget()
    local labels, by_label = saved_labels(saved_connections())
    if #labels == 0 then
        return
    end
    local selection = picker.pick(anyrun, anyrun_plugin, {
        lines = table.concat(labels, "\n") .. "\n",
        max_entries = PAGE_SIZE,
    })
    if not selection then
        return
    end
    local connection = by_label[selection]
    if not connection then
        return
    end
    local confirm = "Forget " .. selection
    local answer = picker.pick(anyrun, anyrun_plugin, {lines = confirm .. "\nCancel\n"})
    if answer == confirm then
        capture({nmcli, "connection", "delete", "uuid", connection.uuid})
    end
end

local function run(entry)
    if entry.kind == "network" then
        if entry.security ~= "" and entry.security ~= "--" then
            process.detach({foot, "-e", nmcli, "--ask", "device", "wifi", "connect", entry.ssid})
        else
            capture({nmcli, "device", "wifi", "connect", entry.ssid})
        end
    elseif entry.kind == "saved" then
        capture({nmcli, "connection", "up", "uuid", entry.connection.uuid})
    elseif entry.kind == "disconnect" then
        capture({nmcli, "connection", "down", "uuid", entry.connection.uuid})
    elseif entry.kind == "radio" then
        capture({nmcli, "radio", "wifi", entry.enabled and "off" or "on"})
    elseif entry.kind == "networking" then
        capture({nmcli, "networking", entry.enabled and "off" or "on"})
    elseif entry.kind == "password" then
        process.detach({foot, "--hold", "-e", nmcli, "device", "wifi", "show-password"})
    elseif entry.kind == "nmtui" then
        process.detach({foot, "-e", "nmtui"})
    end
end

-- Split the item list into pages that fit PAGE_SIZE rows. The action list
-- occupies page one only; a page that leaves items behind also carries the
-- navigation row for the next one.
local function paginate(total, action_count)
    local ranges = {}
    local remaining = total
    local start = 1
    local page = 1
    while true do
        local actions = page == 1 and action_count or 0
        local capacity = PAGE_SIZE - actions - (page > 1 and 1 or 0)
        local more = remaining > capacity
        if more then
            capacity = capacity - 1
        end
        local count = math.min(remaining, capacity)
        ranges[page] = {start = start, count = count, more = more}
        start = start + count
        remaining = remaining - count
        if remaining <= 0 then
            return ranges
        end
        page = page + 1
    end
end

local function menu(requested_page, rescan)
    local entries = {}
    local by_label = {}

    local function add(label, entry)
        entries[#entries + 1] = label
        by_label[label] = entry
    end

    local saved = saved_connections()
    local active = active_wifi()
    local radio = radio_enabled()
    local networking = networking_enabled()

    -- Actions come before the networks: anyrun only renders what fits, and
    -- the access-point list alone can fill a page. Rescan is first so that a
    -- stray Enter is harmless.
    local actions = {}
    if radio then
        actions[#actions + 1] = {"Rescan networks", {kind = "rescan"}}
    end
    if active then
        actions[#actions + 1] = {"Disconnect from " .. active.name, {kind = "disconnect", connection = active}}
        actions[#actions + 1] = {"Show Wi-Fi password / QR", {kind = "password"}}
    end
    if #saved > 0 then
        actions[#actions + 1] = {"Forget a saved network", {kind = "forget"}}
    end
    actions[#actions + 1] = {
        radio and "Turn Wi-Fi off" or "Turn Wi-Fi on",
        {kind = "radio", enabled = radio},
    }
    actions[#actions + 1] = {
        networking and "Turn networking off" or "Turn networking on",
        {kind = "networking", enabled = networking},
    }
    actions[#actions + 1] = {"Open network settings", {kind = "nmtui"}}

    local items = {}
    for _, network in ipairs(visible_networks(rescan)) do
        items[#items + 1] = {
            network_label(network),
            {kind = "network", ssid = network.ssid, security = network.security},
        }
    end
    local labels = saved_labels(saved)
    for index, connection in ipairs(saved) do
        items[#items + 1] = {labels[index], {kind = "saved", connection = connection}}
    end

    local ranges = paginate(#items, #actions)
    local page = math.min(requested_page, #ranges)
    if page == 1 then
        for _, action in ipairs(actions) do
            add(action[1], action[2])
        end
    else
        add("◂ Previous page", {kind = "page", page = page - 1})
    end

    local range = ranges[page]
    for index = range.start, range.start + range.count - 1 do
        add(items[index][1], items[index][2])
    end
    if range.more then
        add("Next page ▸", {kind = "page", page = page + 1})
    end

    return entries, by_label, page
end

-- Rescanning blocks in nmcli until the scan finishes, then reopens the first
-- page; page picks just redraw; every other action runs once and exits.
local page = 1
local rescan = false
while true do
    local entries, by_label, current = menu(page, rescan)
    page = current
    rescan = false

    local selection = picker.pick(anyrun, anyrun_plugin, {
        lines = table.concat(entries, "\n") .. "\n",
        max_entries = PAGE_SIZE,
    })
    if not selection then
        os.exit(0)
    end
    local entry = by_label[selection]
    if not entry then
        os.exit(0)
    end

    if entry.kind == "page" then
        page = entry.page
    elseif entry.kind == "rescan" then
        page = 1
        rescan = true
    elseif entry.kind == "forget" then
        forget()
        os.exit(0)
    else
        run(entry)
        os.exit(0)
    end
end
