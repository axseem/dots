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
      "karabiner-elements"
      "claude-code"
      "brave-browser"
    ];
  };
}
