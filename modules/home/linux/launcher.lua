#!/usr/bin/env lua

-- Single menu with applications and actions, dispatching the selection.
local process = require("axseem.process")
local picker = require("axseem.picker")
local desktop = require("axseem.desktop")
local action_data = require("axseem.actions")

local fuzzel = "@fuzzel@"
local actions = "@actions@"

local function unique(label, seen)
    if not seen[label] then
        seen[label] = 1
        return label
    end
    seen[label] = seen[label] + 1
    return label .. " (" .. seen[label] .. ")"
end

local candidates = {}
local seen = {}

for _, app in ipairs(desktop.entries()) do
    local argv = app.argv
    if app.terminal then
        local terminal = {"foot", "-e"}
        for _, value in ipairs(argv) do
            terminal[#terminal + 1] = value
        end
        argv = terminal
    end
    candidates[#candidates + 1] = {
        label = unique(app.name, seen),
        icon = app.icon,
        argv = argv,
    }
end

for _, entry in ipairs(action_data.entries) do
    candidates[#candidates + 1] = {
        label = unique(entry.label, seen),
        icon = entry.icon,
        action = entry.action,
    }
end

local lines = {}
local by_label = {}
for _, candidate in ipairs(candidates) do
    local line = candidate.label
    if candidate.icon then
        line = line .. "\0icon\x1f" .. candidate.icon
    end
    lines[#lines + 1] = line
    by_label[candidate.label] = candidate
end

local selection = picker.pick(fuzzel, {prompt = "", lines = table.concat(lines, "\n") .. "\n"})
if not selection then
    os.exit(0)
end
local chosen = by_label[selection]
if not chosen then
    os.exit(0)
end

if chosen.action then
    process.detach({actions, "--worker", chosen.action})
else
    process.detach(chosen.argv)
end
