local terminal = "foot"
local fileManager = "nautilus"
local menu = os.getenv("HOME") .. "/.config/rofi/scripts/launcher.sh"
local emoji = "rofi -show emoji"
local mainMod = "SUPER"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
local lock = os.getenv("LOCK_CMD") or "swaylock -f"

hl.on("hyprland.start", function()
    hl.exec_cmd("swaync")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd(string.format(
        "swayidle -w timeout 180 '%s' timeout 240 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' before-sleep '%s'",
        lock,
        lock
    ))
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 0, gaps_out = 0, border_size = 0,
        col = { active_border = "rgb(222222)", inactive_border = "rgb(222222)" },
        layout = "dwindle",
    },
    decoration = {
        shadow = { enabled = false }, blur = { enabled = false }, rounding = 0,
    },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = { disable_hyprland_logo = true, background_color = "rgb(000000)" },
    animations = { enabled = false },
    input = {
        kb_layout = "us", kb_variant = "", kb_model = "", kb_options = "", kb_rules = "",
        follow_mouse = 1, accel_profile = "flat", sensitivity = 0, natural_scroll = true,
        touchpad = { natural_scroll = true },
    },
})

hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/me/screenshots/$(date +'%s_scrnsht.png')"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(emoji))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + U", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lock))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.device({ name = "ugtablet-10-inch-pentablet", output = "eDP-1" })

-- Load host-specific behavior last so a missing host module cannot prevent
-- the common recovery and application binds from being registered.
require("conf.host")
