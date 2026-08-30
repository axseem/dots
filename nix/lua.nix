{pkgs}: let
  packages = pkgs.luajitPackages;
  processModule = packages.toLuaModule (pkgs.writeTextFile {
    name = "axseem-process";
    destination = "/share/lua/${pkgs.luajit.luaversion}/axseem/process.lua";
    text = builtins.readFile ../config/lua/axseem/process.lua;
  });
  runtime = pkgs.luajit.withPackages (_: [
    packages.luaposix
    processModule
  ]);
in {
  inherit processModule runtime;
  interpreter = runtime.interpreter;
}
