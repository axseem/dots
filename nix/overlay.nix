final: _: let
  lua = import ./lua {pkgs = final;};
  emojiData =
    final.runCommand "axseem-emoji-data" {
      nativeBuildInputs = [final.jq];
    } ''
      jq -r 'to_entries[] | .value[] | "\(.emoji)\t\(.description)"' \
        ${final.emoji-runner}/share/emojirunner/emojis.json > $out
    '';
in {
  axseem =
    import ./menu-apps.nix {
      inherit lua emojiData;
      anyrun = "${final.anyrun}/bin/anyrun";
      anyrunPlugin = "${final.anyrun}/lib/libstdin.so";
      wlCopy = "${final.wl-clipboard}/bin/wl-copy";
      cliphist = "${final.cliphist}/bin/cliphist";
      nmcli = "${final.networkmanager}/bin/nmcli";
    }
    // {
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
      sxng = lua.mkApp {
        name = "sxng";
        source = ../modules/nixos/services/searxng/sxng.lua;
        commands = ["sxng"];
        replacements = {
          curl = "${final.curl}/bin/curl";
          jq = "${final.jq}/bin/jq";
        };
      };
    };
}
