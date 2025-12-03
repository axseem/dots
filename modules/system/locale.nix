{pkgs, ...}: {
  i18n = {
    supportedLocales = ["all"];
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
