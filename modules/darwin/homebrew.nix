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
    brews = [
      "docker"
      "docker-compose"
      "gh"
    ];
    casks = [
      "ghostty"
      "nikitabobko/tap/aerospace"
      "openvpn-connect"
      "docker-desktop"
      "elasticvue"
      "visual-studio-code"
      "claude-code"
      "brave-browser"
    ];
  };
}
