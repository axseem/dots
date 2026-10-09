#!/usr/bin/env lua
-- mk: run the Taskfile.lua in the current directory using the global
-- axseem.task library. Installed once; projects ship only a Taskfile.lua.
require("axseem.task").main(arg)
