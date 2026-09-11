{
  pkgs,
  inputs,
}: let
  final = pkgs.extend (import ./overlay.nix);
  lua = final.axseem.lua;
  pre-commit-check = inputs.pre-commit-hooks.lib.${final.stdenv.hostPlatform.system}.run {
    src = ../.;
    hooks = {
      alejandra.enable = true;
      deadnix.enable = true;
    };
  };
  formatterMock = lua.mkApp {
    name = "alejandra-mock";
    source = ./test-mocks/alejandra.lua;
  };
  mimeMock = lua.mkApp {
    name = "xdg-mime-mock";
    source = ./test-mocks/xdg-mime.lua;
  };
  rofiMock = lua.mkApp {
    name = "rofi-test-mock";
    source = ./test-mocks/rofi.lua;
  };
  # `nix fmt`; the automation test builds the same script against the mock.
  formatter = lua.mkApp {
    name = "alejandra";
    source = ./formatter.lua;
    commands = ["alejandra"];
    replacements.alejandra = "${final.alejandra}/bin/alejandra";
  };
  formatterTest = lua.mkApp {
    name = "formatter-test";
    source = ./formatter.lua;
    replacements.alejandra = "${formatterMock}/libexec/alejandra.lua";
  };
in {
  inherit formatter;

  checks = {
    inherit pre-commit-check;
    lua-automation = final.runCommand "lua-automation-test" {
      trueCommand = "${final.coreutils}/bin/true";
      falseCommand = "${final.coreutils}/bin/false";
      printfCommand = "${final.coreutils}/bin/printf";
      catCommand = "${final.coreutils}/bin/cat";
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      testHelpers = ./test-helpers.lua;
      actionsScript = ../config/rofi/scripts/actions.lua;
      bluetoothScript = ../config/rofi/scripts/bluetooth.lua;
      formatterScript = "${formatterTest}/libexec/formatter.lua";
      mimeMock = "${mimeMock}/libexec/xdg-mime.lua";
      lsnixScript = ../modules/home/common/lsnix.lua;
      mimeScript = ../modules/home/linux/text-mime-types.lua;
      secretScript = ../modules/nixos/services/searxng/secret.lua;
      swayidleScript = ../modules/home/linux/swayidle-command.lua;
      sxngScript = ../modules/nixos/services/searxng/sxng.lua;
    } "${lua.interpreter} ${./lua-automation-test.lua}";
    rofi-automation = final.runCommand "rofi-automation-test" {
      lnCommand = "${final.coreutils}/bin/ln";
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      testHelpers = ./test-helpers.lua;
      rofiMock = "${rofiMock}/libexec/rofi.lua";
      rofiScripts = ../config/rofi/scripts;
    } "${lua.interpreter} ${./rofi-automation-test.lua}";
  };

  devShells.default = final.mkShell {
    name = "axseem-dots-dev";
    inherit (pre-commit-check) shellHook;
    buildInputs = pre-commit-check.enabledPackages ++ [lua.runtime];
  };
}
