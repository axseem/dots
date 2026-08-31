{
  pkgs,
  inputs,
}: let
  lua = import ./lua.nix {inherit pkgs;};
  pre-commit-check = inputs.pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
    src = ../.;
    hooks = {
      alejandra.enable = true;
    };
  };
  formatterSource = pkgs.writeTextFile {
    name = "alejandra-source";
    destination = "/libexec/formatter.lua";
    executable = true;
    text =
      builtins.replaceStrings
      ["#!/usr/bin/env lua" "@alejandra@"]
      ["#!${lua.interpreter}" "${pkgs.alejandra}/bin/alejandra"]
      (builtins.readFile ./formatter.lua);
  };
  formatter = pkgs.linkFarm "alejandra" [
    {
      name = "bin/alejandra";
      path = "${formatterSource}/libexec/formatter.lua";
    }
  ];
in {
  inherit formatter;

  checks = {
    inherit pre-commit-check;
    lua-automation = builtins.derivation {
      name = "lua-automation-test";
      system = pkgs.stdenv.hostPlatform.system;
      builder = lua.interpreter;
      args = [./lua-automation-test.lua];
      trueCommand = "${pkgs.coreutils}/bin/true";
      falseCommand = "${pkgs.coreutils}/bin/false";
      printfCommand = "${pkgs.coreutils}/bin/printf";
      catCommand = "${pkgs.coreutils}/bin/cat";
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      actionsScript = ../config/rofi/scripts/actions.lua;
      bluetoothScript = ../config/rofi/scripts/bluetooth.lua;
      formatterScript = ./formatter.lua;
      lsnixScript = ../config/scripts/lsnix.lua;
      mimeScript = ../modules/home/linux/text-mime-types.lua;
      secretScript = ../modules/nixos/services/searxng/secret.lua;
      swayidleScript = ../config/scripts/swayidle-command.lua;
    };
    rofi-automation = builtins.derivation {
      name = "rofi-automation-test";
      system = pkgs.stdenv.hostPlatform.system;
      builder = lua.interpreter;
      args = [./rofi-automation-test.lua];
      lnCommand = "${pkgs.coreutils}/bin/ln";
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      rofiScripts = ../config/rofi/scripts;
    };
  };

  devShells.default = pkgs.mkShell {
    name = "axseem-dots-dev";
    inherit (pre-commit-check) shellHook;
    buildInputs = pre-commit-check.enabledPackages ++ [lua.runtime];
  };
}
