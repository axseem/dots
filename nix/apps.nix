{
  lua,
  fuzzel,
  wlCopy,
  qalc,
  cliphist,
  networkmanager_dmenu,
  emojiData,
}: let
  calc = lua.mkApp {
    name = "axseem-calc";
    source = ../modules/home/linux/calc.lua;
    commands = ["calc"];
    replacements = {
      inherit fuzzel qalc;
      wl_copy = wlCopy;
    };
  };
  clipboard = lua.mkApp {
    name = "axseem-clipboard";
    source = ../modules/home/linux/clipboard.lua;
    commands = ["clipboard"];
    replacements = {
      inherit fuzzel;
      wl_copy = wlCopy;
      cliphist = cliphist;
    };
  };
  emoji = lua.mkApp {
    name = "axseem-emoji";
    source = ../modules/home/linux/emoji.lua;
    commands = ["emoji"];
    replacements = {
      inherit fuzzel;
      wl_copy = wlCopy;
      emoji_data = emojiData;
    };
  };
  bluetooth = lua.mkApp {
    name = "axseem-bluetooth";
    source = ../modules/home/linux/bluetooth.lua;
    commands = ["bluetooth"];
    replacements = {inherit fuzzel;};
  };
  actions = lua.mkApp {
    name = "axseem-actions";
    source = ../modules/home/linux/actions.lua;
    commands = ["actions"];
    replacements = {
      inherit fuzzel networkmanager_dmenu;
      bluetooth = "${bluetooth}/bin/bluetooth";
      emoji = "${emoji}/bin/emoji";
      clipboard = "${clipboard}/bin/clipboard";
      calc = "${calc}/bin/calc";
    };
  };
  launcher = lua.mkApp {
    name = "axseem-launcher";
    source = ../modules/home/linux/launcher.lua;
    commands = ["launcher"];
    replacements = {
      inherit fuzzel;
      actions = "${actions}/bin/actions";
    };
  };
in {
  inherit launcher actions bluetooth emoji clipboard calc;
}
