-- Thin wrapper around anyrun's stdin plugin, which acts as a dmenu
-- replacement: entries on stdin, selection on stdout.
local process = require("axseem.process")

local picker = {}

-- anyrun/plugin are absolute paths baked in at build time.
-- options.lines is the newline-terminated entry list; max_entries limits the
-- number of visible rows.
function picker.pick(anyrun, plugin, options)
    local argv = {
        anyrun,
        "--plugins",
        plugin,
        "--show-results-immediately",
        "true",
        "--hide-plugin-info",
        "true",
        "--max-entries",
        tostring(options.max_entries or 12),
    }

    -- A menu opened by an actions-plugin command can race the closing of the
    -- previous window; the daemon answers "already visible" (exit 1) until
    -- that show is gone.
    local result
    for _ = 1, 5 do
        result = process.capture(argv, options.lines or "", {stderr = "discard"})
        if result.code ~= 1 then
            break
        end
        process.run({"sleep", "0.1"}, {stderr = "discard"})
    end

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
