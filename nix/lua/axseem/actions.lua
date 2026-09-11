-- Menu entries shared by the combined launcher and the actions menu.
local actions = {}

actions.entries = {
    {label = "Wi-Fi settings", icon = "network-wireless-symbolic", action = "wifi"},
    {label = "Bluetooth settings", icon = "bluetooth-symbolic", action = "bluetooth"},
    {label = "Audio settings", icon = "audio-volume-high-symbolic", action = "audio"},
    {label = "Clipboard history", icon = "edit-paste-symbolic", action = "clipboard"},
    {label = "Calculator", icon = "accessories-calculator", action = "calculator"},
    {label = "Browse files", icon = "folder-symbolic", action = "files"},
    {label = "Emoji picker", icon = "face-smile-symbolic", action = "emoji"},
    {label = "Screenshot area", icon = "camera-photo-symbolic", action = "screenshot-area"},
    {label = "Screenshot full screen", icon = "camera-photo-symbolic", action = "screenshot-full"},
    {label = "Lock screen", icon = "system-lock-screen-symbolic", action = "lock"},
    {label = "Suspend", icon = "media-playback-pause-symbolic", action = "suspend"},
    {label = "Log out", icon = "system-log-out-symbolic", action = "logout"},
    {label = "Restart", icon = "system-reboot-symbolic", action = "reboot"},
    {label = "Power off", icon = "system-shutdown-symbolic", action = "poweroff"},
}

return actions
