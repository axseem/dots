final: prev: let
  lua = import ./lua {pkgs = final;};
in {
  axseem = {
    inherit lua;
    lsnix = lua.mkApp {
      name = "lsnix";
      source = ../modules/home/common/lsnix.lua;
      commands = ["lsnix"];
    };
    swayidle-commands = lua.mkApp {
      name = "swayidle-commands";
      source = ../modules/home/linux/swayidle-command.lua;
      commands = [
        "swayidle-lock"
        "swayidle-displays-off"
        "swayidle-displays-on"
      ];
    };
  };
}
