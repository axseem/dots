{...}: {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    taps = [
      "nikitabobko/tap"
    ];
    # nix channel provides gh (home/cli.nix) and VSCodium (home/vscodium);
    # docker CLI + compose v2 ship with the Docker Desktop cask.
    brews = [];
    casks = [
      "ghostty"
      "nikitabobko/tap/aerospace"
      "openvpn-connect"
      "docker-desktop"
      "elasticvue"
      "claude-code"
      "brave-browser"
    ];
  };
}
