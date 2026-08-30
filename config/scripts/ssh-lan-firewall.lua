#!/usr/bin/env lua

local process = require("axseem.process")

local mode = assert(arg[1], "mode is required")
local iptables = assert(arg[2], "iptables path is required")
local interface = assert(arg[3], "interface is required")
local subnet = assert(arg[4], "subnet is required")
local port = assert(arg[5], "port is required")

local function rule(operation)
    local argv = {
        iptables,
        "-w",
        operation,
        "nixos-fw",
    }
    if operation == "-I" then
        argv[#argv + 1] = "1"
    end
    for _, value in ipairs({
        "-i",
        interface,
        "-s",
        subnet,
        "-p",
        "tcp",
        "--dport",
        port,
        "-m",
        "conntrack",
        "--ctstate",
        "NEW",
        "-j",
        "nixos-fw-accept",
    }) do
        argv[#argv + 1] = value
    end
    return argv
end

local exists = process.run(rule("-C"), { stdout = "discard", stderr = "discard" }) == 0
if mode == "apply" then
    if not exists then
        -- The completed NixOS chain already ends in a refusal rule, so insert
        -- this narrow accept rule at the front rather than appending after it.
        os.exit(process.run(rule("-I")))
    end
elseif mode == "remove" then
    if exists then
        os.exit(process.run(rule("-D")))
    end
else
    io.stderr:write("unknown firewall mode: " .. mode .. "\n")
    os.exit(2)
end
