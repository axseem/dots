{pkgs, ...}: {
  i18n = {
    supportedLocales = ["en_US.UTF-8" "cs_CZ.UTF-8"];
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Prague";

  environment.systemPackages = with pkgs; [
    nuspell
    hyphen
    hunspell
    hunspellDicts.en_US
  ];
}
