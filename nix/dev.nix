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
  anyrunMock = lua.mkApp {
    name = "anyrun-mock";
    source = ./test-mocks/anyrun.lua;
    commands = ["anyrun"];
  };
  commandMock = lua.mkApp {
    name = "command-mock";
    source = ./test-mocks/command.lua;
    commands = [
      "busctl"
      "bluetoothctl"
      "rfkill"
      "mkdir"
      "sleep"
      "slurp"
      "grim"
      "date"
      "wl-copy"
      "cliphist"
      "nmcli"
      "swaylock"
      "loginctl"
    ];
  };
  testApps = import ./apps.nix {
    inherit lua;
    anyrun = "${anyrunMock}/bin/anyrun";
    anyrunPlugin = "mock-plugin";
    wlCopy = "${commandMock}/bin/wl-copy";
    cliphist = "${commandMock}/bin/cliphist";
    nmcli = "${commandMock}/bin/nmcli";
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
      sleepCommand = "${final.coreutils}/bin/sleep";
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      testHelpers = ./test-helpers.lua;
      actionsScript = ../modules/home/linux/actions.lua;
      bluetoothScript = ../modules/home/linux/bluetooth.lua;
      clipboardScript = ../modules/home/linux/clipboard.lua;
      wifiScript = ../modules/home/linux/wifi.lua;
      formatterScript = "${formatterTest}/libexec/formatter.lua";
      mimeMock = "${mimeMock}/libexec/xdg-mime.lua";
      lsnixScript = ../modules/home/common/lsnix.lua;
      mimeScript = ../modules/home/linux/text-mime-types.lua;
      secretScript = ../modules/nixos/services/searxng/secret.lua;
      swayidleScript = ../modules/home/linux/swayidle-command.lua;
      sxngScript = ../modules/nixos/services/searxng/sxng.lua;
    } "${lua.interpreter} ${./lua-automation-test.lua}";
    anyrun-automation = final.runCommand "anyrun-automation-test" {
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      sleepCommand = "${final.coreutils}/bin/sleep";
      testHelpers = ./test-helpers.lua;
      commandBin = "${commandMock}/bin";
      actionsApp = "${testApps.actions}/bin/actions";
      bluetoothApp = "${testApps.bluetooth}/bin/bluetooth";
      clipboardApp = "${testApps.clipboard}/bin/clipboard";
      wifiApp = "${testApps.wifi}/bin/wifi";
    } "${lua.interpreter} ${./anyrun-automation-test.lua}";
  };

  devShells.default = final.mkShell {
    name = "axseem-dots-dev";
    inherit (pre-commit-check) shellHook;
    buildInputs = pre-commit-check.enabledPackages ++ [lua.runtime];
  };
}
