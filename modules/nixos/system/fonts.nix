{pkgs, ...}: {
  fonts.fontconfig = {
    allowBitmaps = true;
    useEmbeddedBitmaps = true;
  };
  fonts.fontDir.enable = true;
}
