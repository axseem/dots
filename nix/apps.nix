{
  lua,
  anyrun,
  anyrunPlugin,
  wlCopy,
  cliphist,
  nmcli,
}: let
  actions = lua.mkApp {
    name = "axseem-actions";
    source = ../modules/home/linux/actions.lua;
    commands = ["actions"];
  };
  bluetooth = lua.mkApp {
    name = "axseem-bluetooth";
    source = ../modules/home/linux/bluetooth.lua;
    commands = ["bluetooth"];
    replacements = {
      inherit anyrun;
      anyrun_plugin = anyrunPlugin;
    };
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
  wifi = lua.mkApp {
    name = "axseem-wifi";
    source = ../modules/home/linux/wifi.lua;
    commands = ["wifi"];
    replacements = {
      inherit anyrun nmcli;
      anyrun_plugin = anyrunPlugin;
    };
  };
in {
  inherit actions bluetooth clipboard wifi;
}
