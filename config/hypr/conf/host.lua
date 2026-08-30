local internalMonitor = "eDP-1"

local function enableInternalMonitor()
    hl.monitor({
        output = internalMonitor,
        disabled = false,
        mode = "2880x1800@120.00Hz",
        position = "0x0",
        scale = 2,
    })
end

local function hasExternalMonitor()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= internalMonitor then
            return true
        end
    end

    return false
end

enableInternalMonitor()
hl.workspace_rule({ workspace = "1", monitor = internalMonitor, default = true })

local function closeLid()
    if hasExternalMonitor() then
        hl.monitor({ output = internalMonitor, disabled = true })
    else
        hl.exec_cmd("systemctl suspend")
    end
end

hl.bind("switch:on:Lid Switch", closeLid, { locked = true })
hl.bind("switch:off:Lid Switch", enableInternalMonitor, { locked = true })
