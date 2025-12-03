#!/usr/bin/env bash

# Configuration
THEME="axseem"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-$HOME/me/library/img/screenshots}"

# Helper function for rofi
rofi_cmd() {
    rofi -dmenu -theme "$THEME" "$@"
}

# Submenu functions
menu_screenshot() {
    local file="$SCREENSHOT_DIR/$(date +'%s_scrnsht.png')"
    mkdir -p "$SCREENSHOT_DIR"

    local selected
    selected=$(printf "full\narea\nwindow" | rofi_cmd -p "screenshot" -no-auto-select)

    case "$selected" in
        "full")   grim - | tee "$file" | wl-copy ;;
        "area")   grim -g "$(slurp)" - | tee "$file" | wl-copy ;;
        "window") grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | tee "$file" | wl-copy ;;
    esac
}

menu_power() {
    local selected
    selected=$(printf "lock\nlog out\nsuspend\nrestart\nturn off" | rofi_cmd -p "power" -no-auto-select)

    case "$selected" in
        "lock")     swaylock -f -i eDP-1:~/.config/swaylock/lockscreen.png ;;
        "log out")  hyprctl dispatch exit ;;
        "suspend")  systemctl suspend ;;
        "restart")  systemctl reboot ;;
        "turn off") systemctl poweroff ;;
    esac
}

# Main menu actions
run_apps()      { rofi -show drun -theme "$THEME"; }
run_wifi()      { networkmanager_dmenu -no-auto-select; }
run_bluetooth() { rofi-bluetooth -theme "$THEME" -no-auto-select; }
run_calc()      { rofi -show calc -modi calc -no-show-match -no-sort -theme "$THEME" -no-auto-select; }
run_clip()      { cliphist list | rofi_cmd -p "clipboard" -no-auto-select | cliphist decode | wl-copy; }
run_files()     { rofi -show filebrowser -theme "$THEME" -no-auto-select; }
run_emoji()     { rofi -show emoji -theme "$THEME" -no-auto-select; }

# Main logic
main() {
    local options="apps\nwifi\nbluetooth\ncalc\nclipboard\nfiles\nscreenshot\nemoji\npower"
    
    local selected
    selected=$(printf "$options" | rofi_cmd -p "menu")

    case "$selected" in
        "apps")       run_apps ;;
        "wifi")       run_wifi ;;
        "bluetooth")  run_bluetooth ;;
        "calc")       run_calc ;;
        "clipboard")  run_clip ;;
        "files")      run_files ;;
        "screenshot") menu_screenshot ;;
        "emoji")      run_emoji ;;
        "power")      menu_power ;;
    esac
}

main
