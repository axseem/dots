{pkgs, ...}: {
  fonts.fontconfig = {
    allowBitmaps = true;
    useEmbeddedBitmaps = true;
  };
  fonts.enableFontDir = true;
}
