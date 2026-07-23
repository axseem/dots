#!/usr/bin/env bash

set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
actions="$config_home/rofi/scripts/actions"

exec rofi \
    -show combi \
    -modes "combi,drun,calc,actions:$actions" \
    -combi-modes "drun,actions,calc"
