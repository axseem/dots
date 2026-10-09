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
      foot = "${final.foot}/bin/foot";
    }
    // {
      inherit lua;

      # make/just replacement: `mk <task>` runs Taskfile.lua via axseem.task.
      mk = lua.mkApp {
        name = "mk";
        source = ./lua/mk.lua;
        commands = ["mk"];
      };
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
      tmux-session = lua.mkApp {
        name = "tmux-session";
        source = ../modules/home/linux/tmux-session.lua;
        commands = ["tmux-session"];
        replacements = {
          tmux = "${final.tmux}/bin/tmux";
          bash = "${final.bash}/bin/bash";
          resurrectSave = "${final.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh";
          resurrectRestore = "${final.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh";
          path = final.lib.makeBinPath [
            final.tmux
            final.bash
            final.coreutils
            final.gnugrep
            final.gnused
            final.gawk
            final.procps
            final.findutils
          ];
        };
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
