{pkgs}: let
  packages = pkgs.luajitPackages;
  module = name: source:
    packages.toLuaModule (pkgs.writeTextFile {
      name = "axseem-${name}";
      destination = "/share/lua/${pkgs.luajit.luaversion}/axseem/${name}.lua";
      text = builtins.readFile source;
    });
  runtime = pkgs.luajit.withPackages (_: [
    packages.luaposix
    (module "process" ./axseem/process.lua)
    (module "picker" ./axseem/picker.lua)
    (module "desktop" ./axseem/desktop.lua)
    (module "actions" ./axseem/actions.lua)
  ]);
in {
  inherit runtime;
  inherit (runtime) interpreter;

  # Build a repo Lua script into a derivation exposing libexec/<file> (with
  # @replacements@ substituted and the shebang patched to the runtime
  # interpreter) plus a bin/<command> symlink for each requested command.
  mkApp = {
    name,
    source,
    commands ? [],
    replacements ? {},
  }: let
    file = baseNameOf (toString source);
    script = pkgs.replaceVarsWith {
      src = source;
      inherit replacements;
      dir = "libexec";
      isExecutable = true;
      nativeBuildInputs = [runtime];
      postBuild = "patchShebangs $out/libexec/${file}";
    };
  in
    pkgs.linkFarm name (
      [
        {
          name = "libexec/${file}";
          path = "${script}/libexec/${file}";
        }
      ]
      ++ map (command: {
        name = "bin/${command}";
        path = "${script}/libexec/${file}";
      })
      commands
    );
}
