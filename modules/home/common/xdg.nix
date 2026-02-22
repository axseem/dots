{
  config,
  lib,
  ...
}: {
  xdg.configFile = {
    "ghostty/config".source = ../../../config/ghostty/config;
    "ghostty/themes/Carbonfox".source = ../../../config/ghostty/themes/Carbonfox;
    "foot".source = ../../../config/foot;
  };
}
