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
      "openvpn-connect"
      "docker-desktop"
      "elasticvue"
      "visual-studio-code"
      "claude-code"
      "brave-browser"
    ];
  };
}
