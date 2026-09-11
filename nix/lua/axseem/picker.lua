-- Thin wrapper around fuzzel's dmenu mode, shared by the menu scripts.
local process = require("axseem.process")

local picker = {}

-- options:
--   prompt: string shown before the input
--   placeholder: optional grey hint text
--   lines: newline-terminated entries (may be empty to ask for input)
--   args: extra fuzzel arguments
-- Returns the selected text, or nil if the user cancelled.
function picker.pick(fuzzel, options)
    local argv = {fuzzel, "--dmenu", "--prompt", options.prompt or ""}
    if options.placeholder then
        argv[#argv + 1] = "--placeholder"
        argv[#argv + 1] = options.placeholder
    end
    for _, value in ipairs(options.args or {}) do
        argv[#argv + 1] = value
    end

    local result = process.capture(argv, options.lines or "", {stderr = "discard"})
    if result.code ~= 0 then
        return nil, result.code
    end
    local selection = result.out:gsub("[\r\n]+$", "")
    if selection == "" then
        return nil, result.code
    end
    return selection, result.code
end

return picker
