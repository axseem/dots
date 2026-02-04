{...}: {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    brews = [
      "docker"
      "docker-compose"
      "gh"
    ];
    casks = [
      "ghostty"
      "aerospace"
      "openvpn-connect"
      "docker-desktop"
      "elasticvue"
      "visual-studio-code"
      "claude-code"
      "brave-browser"
      "foot"
    ];
  };
}
