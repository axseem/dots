{
  lua,
  anyrun,
  anyrunPlugin,
  wlCopy,
  cliphist,
  nmcli,
  foot,
  emojiData,
}: let
  actions = lua.mkApp {
    name = "axseem-actions";
    source = ../modules/home/linux/actions.lua;
    commands = ["actions"];
  };
  clipboard = lua.mkApp {
    name = "axseem-clipboard";
    source = ../modules/home/linux/clipboard.lua;
    commands = ["clipboard"];
    replacements = {
      inherit anyrun cliphist;
      anyrun_plugin = anyrunPlugin;
      wl_copy = wlCopy;
    };
  };
  emoji = lua.mkApp {
    name = "axseem-emoji";
    source = ../modules/home/linux/emoji.lua;
    commands = ["emoji"];
    replacements = {
      inherit anyrun;
      anyrun_plugin = anyrunPlugin;
      wl_copy = wlCopy;
      emoji_data = emojiData;
    };
  };
  wifi = lua.mkApp {
    name = "axseem-wifi";
    source = ../modules/home/linux/wifi.lua;
    commands = ["wifi"];
    replacements = {
      inherit anyrun nmcli foot;
      anyrun_plugin = anyrunPlugin;
    };
  };
in {
  inherit actions clipboard emoji wifi;
}
