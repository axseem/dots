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
  fuzzelMock = lua.mkApp {
    name = "fuzzel-mock";
    source = ./test-mocks/fuzzel.lua;
    commands = ["fuzzel"];
  };
  commandMock = lua.mkApp {
    name = "command-mock";
    source = ./test-mocks/command.lua;
    commands = [
      "systemd-run"
      "networkmanager_dmenu"
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
      "qalc"
    ];
  };
  testEmojiData = final.runCommand "test-emoji-data" {} "cp ${./test-mocks/emoji-data} $out";
  testApps = import ./apps.nix {
    inherit lua;
    fuzzel = "${fuzzelMock}/bin/fuzzel";
    wlCopy = "${commandMock}/bin/wl-copy";
    qalc = "${commandMock}/bin/qalc";
    cliphist = "${commandMock}/bin/cliphist";
    networkmanager_dmenu = "${commandMock}/bin/networkmanager_dmenu";
    emojiData = testEmojiData;
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
      calcScript = ../modules/home/linux/calc.lua;
      clipboardScript = ../modules/home/linux/clipboard.lua;
      emojiScript = ../modules/home/linux/emoji.lua;
      launcherScript = ../modules/home/linux/launcher.lua;
      formatterScript = "${formatterTest}/libexec/formatter.lua";
      mimeMock = "${mimeMock}/libexec/xdg-mime.lua";
      lsnixScript = ../modules/home/common/lsnix.lua;
      mimeScript = ../modules/home/linux/text-mime-types.lua;
      secretScript = ../modules/nixos/services/searxng/secret.lua;
      swayidleScript = ../modules/home/linux/swayidle-command.lua;
      sxngScript = ../modules/nixos/services/searxng/sxng.lua;
    } "${lua.interpreter} ${./lua-automation-test.lua}";
    fuzzel-automation = final.runCommand "fuzzel-automation-test" {
      luaCommand = lua.interpreter;
      runtimeBin = "${lua.runtime}/bin";
      sleepCommand = "${final.coreutils}/bin/sleep";
      testHelpers = ./test-helpers.lua;
      commandBin = "${commandMock}/bin";
      fuzzelMock = "${fuzzelMock}/bin/fuzzel";
      emojiData = testEmojiData;
      actionsApp = "${testApps.actions}/bin/actions";
      launcherApp = "${testApps.launcher}/bin/launcher";
      calcApp = "${testApps.calc}/bin/calc";
      clipboardApp = "${testApps.clipboard}/bin/clipboard";
      emojiApp = "${testApps.emoji}/bin/emoji";
      bluetoothApp = "${testApps.bluetooth}/bin/bluetooth";
    } "${lua.interpreter} ${./fuzzel-automation-test.lua}";
  };

  devShells.default = final.mkShell {
    name = "axseem-dots-dev";
    inherit (pre-commit-check) shellHook;
    buildInputs = pre-commit-check.enabledPackages ++ [lua.runtime];
  };
}
