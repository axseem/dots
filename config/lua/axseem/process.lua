local posix = require("posix")
local stdio = require("posix.stdio")
local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")

local process = {}

local function checked_argv(argv)
    assert(type(argv) == "table", "argv must be a table")
    assert(#argv > 0, "argv must not be empty")

    local copy = {}
    for index = 1, #argv do
        assert(type(argv[index]) == "string", "argv entries must be strings")
        copy[index] = argv[index]
    end
    return copy
end

local function temporary_file(contents)
    local file = assert(io.tmpfile())
    if contents ~= nil then
        assert(file:write(contents))
        assert(file:seek("set", 0))
    end
    return file
end

local function redirect(file, descriptor)
    assert(unistd.dup2(assert(stdio.fileno(file)), descriptor))
end

local function exit_code(reason, status)
    if reason == "exited" then
        return status
    end
    if reason == "killed" or reason == "stopped" then
        return 128 + status
    end
    error("unexpected child status: " .. tostring(reason))
end

local function execute(argv, input, capture_stdout, options)
    argv = checked_argv(argv)
    options = options or {}

    assert(options.stdout == nil or options.stdout == "discard", "invalid stdout option")
    assert(options.stderr == nil or options.stderr == "discard", "invalid stderr option")

    local input_file = input ~= nil and temporary_file(input) or nil
    local output_file = capture_stdout and temporary_file() or nil
    local null_file =
        (options.stdout == "discard" or options.stderr == "discard")
        and assert(io.open("/dev/null", "wb"))
        or nil

    io.stdout:flush()
    io.stderr:flush()

    local pid, message = unistd.fork()
    assert(pid, message)

    if pid == 0 then
        if input_file then
            redirect(input_file, unistd.STDIN_FILENO)
        end
        if output_file then
            redirect(output_file, unistd.STDOUT_FILENO)
        elseif options.stdout == "discard" then
            redirect(null_file, unistd.STDOUT_FILENO)
        end
        if options.stderr == "discard" then
            redirect(null_file, unistd.STDERR_FILENO)
        end

        local _, exec_message = posix.execx(argv)
        unistd.write(
            unistd.STDERR_FILENO,
            "failed to execute " .. argv[1] .. ": " .. tostring(exec_message) .. "\n"
        )
        unistd._exit(127)
    end

    local waited_pid, reason, status = wait.wait(pid)
    assert(waited_pid, reason)

    local output = nil
    if output_file then
        assert(output_file:seek("set", 0))
        output = assert(output_file:read("*a"))
    end

    if input_file then
        input_file:close()
    end
    if output_file then
        output_file:close()
    end
    if null_file then
        null_file:close()
    end

    return exit_code(reason, status), output, reason
end

function process.run(argv, options)
    local code = execute(argv, nil, false, options)
    return code
end

function process.capture(argv, input, options)
    local code, output, reason = execute(argv, input, true, options)
    return { code = code, out = output, reason = reason }
end

function process.feed(argv, input, options)
    local code = execute(argv, input, false, options)
    return code
end

function process.exec(argv)
    argv = checked_argv(argv)
    local _, message = posix.execx(argv)
    error("failed to execute " .. argv[1] .. ": " .. tostring(message))
end

return process
