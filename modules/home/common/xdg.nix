{...}: {
  xdg.configFile = {
    "ghostty".source = ../../../config/ghostty;
    "foot".source = ../../../config/foot;
    "opencode" = {
      source = ../../../config/opencode;
      force = true;
    };
  };
}
