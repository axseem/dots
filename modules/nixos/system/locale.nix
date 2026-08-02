{pkgs, ...}: {
  i18n = {
    # defaultLocale (en_US.UTF-8) is built automatically; extraLocales adds
    # the Czech locale on top.
    extraLocales = ["cs_CZ.UTF-8"];
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
