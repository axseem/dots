-- axseem.task: a make/just replacement. Tasks are VALUES (lazy argv thunks),
-- not callbacks. Correctness: every leaf is an argv (execve); no shell unless
-- you ask for it with shell()/sh(). Functions remain as the fn() escape hatch.
-- Caller arguments: args() in a task argv expands to the tokens after `--`.
local process = require("axseem.process")
local stat = require("posix.sys.stat")
local unistd = require("posix.unistd")
local stdlib = require("posix.stdlib")
local wait = require("posix.sys.wait")
local glob = require("posix.glob")

local unpack = table.unpack or unpack

local M = {quiet = false, dry = false, argv = {}}
local tasks, order, default_name = {}, {}, nil

local function die(fmt, ...) io.stderr:write("task: " .. string.format(fmt, ...) .. "\n") os.exit(1) end
local function mtime(p) local s = stat.stat(p) return s and s.st_mtime or nil end
local function exists(p) return mtime(p) ~= nil end

-- ---------- specs: lazy command values ----------
local function spec(kind, payload) return {__spec = kind, payload = payload} end
local function is_spec(v) return type(v) == "table" and v.__spec ~= nil end
local function cmd(...) return spec("cmd", {...}) end
local function bin(exe) return function(...) return cmd(exe, ...) end end
local function shell(s) return spec("shell", s) end
local function seq(...) return spec("seq", {...}) end
local function par(...) return spec("par", {...}) end
local function needs(...) return spec("needs", {...}) end
local function in_dir(d, s) return spec("in_dir", {dir = d, spec = s}) end
local function with_env(e, s) return spec("env", {env = e, spec = s}) end
local function fn(f) return spec("fn", f) end
-- Placeholder for caller arguments: expands to the tokens after `--`.
local function args() return spec("args") end

-- ---------- eager primitives (for logic inside fn) ----------
local function echo(argv) if not M.quiet then io.stderr:write(table.concat(argv, " ") .. "\n") end end
local function try(...)
   local argv = {...}
   echo(argv)
   if M.dry then return 0 end
   return process.run(argv)
end
local function run(...)
   local argv = {...}
   local code = try(unpack(argv))
   if code ~= 0 then die("command failed (%d): %s", code, table.concat(argv, " ")) end
end
local function sh(cmdline) run("/bin/sh", "-c", cmdline) end
local function capture(...)
   if M.dry then return "" end
   local argv = {...}
   local r = process.capture(argv)
   if r.code ~= 0 then die("command failed (%d): %s", r.code, table.concat(argv, " ")) end
   return r.out
end
local function lines(...)
   local out = {}
   for l in capture(...):gmatch("[^\n]+") do out[#out + 1] = l end
   return out
end
local function files(...)
   local out, seen = {}, {}
   for _, p in ipairs({...}) do
      for _, f in ipairs(glob.glob(p) or {}) do
         if not seen[f] then seen[f] = true out[#out + 1] = f end
      end
   end
   table.sort(out)
   return out
end
local function any_exec(mode)
   local u, g, o = math.floor(mode / 64) % 8, math.floor(mode / 8) % 8, mode % 8
   return u % 2 == 1 or g % 2 == 1 or o % 2 == 1
end
local function is_regular(mode) return math.floor(mode / 4096) % 16 == 8 end
local function require_tool(name)
   local found
   for dir in (os.getenv("PATH") or ""):gmatch("[^:]+") do
      local p = dir .. "/" .. name
      local st = stat.stat(p)
      if st and is_regular(st.st_mode) and any_exec(st.st_mode) then found = p break end
   end
   if not found then die("required tool not found: %s", name) end
   return found
end

-- ---------- spec execution ----------
-- True if the spec tree contains a caller-arguments placeholder.
local function has_args(s)
   if not is_spec(s) then return false end
   local k = s.__spec
   if k == "args" then return true end
   if k == "cmd" or k == "seq" or k == "par" then
      for _, x in ipairs(s.payload) do if has_args(x) then return true end end
   elseif k == "in_dir" or k == "env" then
      return has_args(s.payload.spec)
   end
   return false
end

local function exec_spec(s)
   local k = s.__spec
   if k == "cmd" then
      local a = {}
      for _, x in ipairs(s.payload) do
         if is_spec(x) and x.__spec == "args" then
            for _, v in ipairs(M.argv) do a[#a + 1] = v end
         else
            a[#a + 1] = x
         end
      end
      echo(a)
      if not M.dry then
         local code = process.run(a)
         if code ~= 0 then die("command failed (%d): %s", code, table.concat(a, " ")) end
      end
   elseif k == "shell" then
      if not M.quiet then io.stderr:write(s.payload .. "\n") end
      if not M.dry then
         local code = process.run({"/bin/sh", "-c", s.payload})
         if code ~= 0 then die("command failed (%d): %s", code, s.payload) end
      end
   elseif k == "seq" then
      for _, x in ipairs(s.payload) do exec_spec(x) end
   elseif k == "par" then
      local pids = {}
      for _, x in ipairs(s.payload) do
         local pid = unistd.fork()
         if pid == 0 then exec_spec(x) os.exit(0) end
         pids[#pids + 1] = pid
      end
      for _, pid in ipairs(pids) do
         local _, reason, code = wait.wait(pid)
         if reason ~= "exited" or code ~= 0 then die("parallel job failed") end
      end
   elseif k == "fn" then s.payload()
   elseif k == "needs" then -- no-op; handled by the scheduler
   elseif k == "in_dir" then
      local old = assert(unistd.getcwd())
      assert(unistd.chdir(s.payload.dir))
      local ok, err = pcall(exec_spec, s.payload.spec)
      unistd.chdir(old)
      if not ok then error(err) end
   elseif k == "env" then
      local saved = {}
      for name, value in pairs(s.payload.env) do saved[name] = os.getenv(name) stdlib.setenv(name, value, true) end
      local ok, err = pcall(exec_spec, s.payload.spec)
      for name, old in pairs(saved) do stdlib.setenv(name, old or "", true) end
      if not ok then error(err) end
   else
      die("unknown spec: %s", tostring(k))
   end
end

-- ---------- task registry + scheduler ----------
local function up_to_date(t)
   if not (t.inputs and t.outputs and #t.inputs > 0 and #t.outputs > 0) then return false end
   local newest = -1
   for _, p in ipairs(t.inputs) do local m = mtime(p) if not m then return false end if m > newest then newest = m end end
   for _, p in ipairs(t.outputs) do local m = mtime(p) if not m or m < newest then return false end end
   return true
end

local function task(name, body, opts)
   opts = opts or {}
   local deps = opts.deps or {}
   if is_spec(body) and body.__spec == "needs" then
      for _, d in ipairs(body.payload) do deps[#deps + 1] = d end
      body = nil
   end
   local runfn
   if body == nil then runfn = function() end
   elseif type(body) == "function" then runfn = body
   elseif is_spec(body) then runfn = function() exec_spec(body) end
   else die("task %q: body must be a command spec or function", name) end
   if tasks[name] then die("duplicate task %q", name) end
   tasks[name] = {name = name, desc = opts.desc, deps = deps, inputs = opts.inputs, outputs = opts.outputs, fn = runfn, body_spec = is_spec(body) and body or nil}
   order[#order + 1] = name
end

local function default(name) default_name = name end

local dsl = {task = task, default = default, needs = needs, cmd = cmd, bin = bin, shell = shell,
             seq = seq, par = par, fn = fn, args = args, in_dir = in_dir, with_env = with_env,
             run = run, try = try, capture = capture, lines = lines, files = files,
             require_tool = require_tool, exists = exists}

local function load_taskfile(path)
   local chunk, err = loadfile(path)
   if not chunk then die("cannot load %s: %s", path, err) end
   local env = setmetatable({}, {__index = _G})
   for k, v in pairs(dsl) do env[k] = v end
   if setfenv then setfenv(chunk, env) else die("needs Lua 5.1/LuaJIT") end
   chunk()
end

local function plan(names)
   local level, state = {}, {}
   local function visit(name, stack)
      local t = tasks[name] or die("unknown task %q", name)
      if state[name] == "done" then return level[name] end
      if state[name] == "visiting" then die("dependency cycle: %s -> %s", table.concat(stack, " -> "), name) end
      state[name] = "visiting"
      local l = 0
      for _, d in ipairs(t.deps) do l = math.max(l, visit(d, stack)) end
      state[name] = "done" level[name] = l + 1 return l + 1
   end
   for _, n in ipairs(names) do visit(n, {n}) end
   return level
end

local function execute(names, jobs, force)
   local level = plan(names)
   local waves, maxl = {}, 0
   for n, l in pairs(level) do
      waves[l] = waves[l] or {}
      table.insert(waves[l], n)
      if l > maxl then maxl = l end
   end
   local function do_one(name)
      local t = tasks[name]
      if not force and up_to_date(t) then
         if not M.quiet then io.stderr:write("task: " .. name .. " is up to date\n") end
         return
      end
      if M.dry then io.stderr:write("task: would run " .. name .. "\n") return end
      if not M.quiet then io.stderr:write("task: " .. name .. "\n") end
      t.fn()
   end
   for l = 1, maxl do
      local w, i = waves[l], 1
      if jobs <= 1 then
         while i <= #w do do_one(w[i]) i = i + 1 end
      else
         local running = {}
         local function reap()
            local pid = running[1] table.remove(running, 1)
            local _, reason, code = wait.wait(pid)
            if reason ~= "exited" or code ~= 0 then die("job failed") end
         end
         while i <= #w or #running > 0 do
            while i <= #w and #running < jobs do
               local name = w[i] i = i + 1
               local t = tasks[name]
               if not force and up_to_date(t) then io.stderr:write("task: " .. name .. " is up to date\n")
               elseif M.dry then io.stderr:write("task: would run " .. name .. "\n")
               else
                  local pid = unistd.fork()
                  if pid == 0 then local ok = pcall(t.fn) os.exit(ok and 0 or 1) end
                  table.insert(running, pid)
               end
            end
            if #running > 0 then reap() end
         end
      end
   end
end

local function usage()
   io.stderr:write([[
task [options] [task] [-- args ...]

  -l, --list     list tasks        -j N   run up to N jobs in parallel
  -n, --dry-run  print the DAG     -f     ignore up-to-date checks
  -q, --quiet    suppress echo     --file PATH

  args after -- fill the selected task's args() placeholder.
]])
end

local function main(argv)
   argv = argv or arg
   local names, passthrough, jobs, force, list, file = {}, {}, 1, false, false, "Taskfile.lua"
   local i = 1
   while i <= #argv do
      local a = argv[i]
      if a == "--" then
         for j = i + 1, #argv do passthrough[#passthrough + 1] = argv[j] end
         break
      elseif a == "-l" or a == "--list" then list = true
      elseif a == "-n" or a == "--dry-run" then M.dry = true
      elseif a == "-f" or a == "--force" then force = true
      elseif a == "-q" or a == "--quiet" then M.quiet = true
      elseif a == "-j" or a == "--jobs" then i = i + 1 jobs = tonumber(argv[i]) or die("-j needs a number")
      elseif a:match("^%-j%d+$") then jobs = tonumber(a:sub(3))
      elseif a == "--file" then i = i + 1 file = argv[i]
      elseif a == "-h" or a == "--help" then usage() return
      elseif a:sub(1, 1) == "-" then die("unknown option %s", a)
      else names[#names + 1] = a end
      i = i + 1
   end
   load_taskfile(file)
   if list then
      for _, n in ipairs(order) do io.stdout:write(string.format("  %-14s %s\n", n, tasks[n].desc or "")) end
      return
   end
   if #names == 0 then names = {default_name or order[1]} end
   if #passthrough > 0 then
      if #names ~= 1 then die("arguments require exactly one task") end
      local t = tasks[names[1]] or die("unknown task %q", names[1])
      if not (t.body_spec and has_args(t.body_spec)) then die("task %q does not accept arguments", names[1]) end
   end
   M.argv = passthrough
   execute(names, jobs, force)
end

M.main = main
M.task, M.default, M.needs = task, default, needs
M.cmd, M.bin, M.shell, M.seq, M.par, M.fn, M.args = cmd, bin, shell, seq, par, fn, args
M.in_dir, M.with_env = in_dir, with_env
M.run, M.try, M.capture, M.lines, M.files = run, try, capture, lines, files
M.require_tool, M.exists = require_tool, exists
return M
