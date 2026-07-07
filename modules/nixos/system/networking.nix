{pkgs, ...}: {
  networking = {
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
    };

    extraHosts = ''
      # Addiction Blocklist
      127.0.0.1 www.youtube.com
      127.0.0.1 www.reddit.com
      127.0.0.1 news.ycombinator.com
      127.0.0.1 www.chess.com
      127.0.0.1 www.lichess.org
      127.0.0.1 www.instagram.com

      # AI
      127.0.0.1 openrouter.ai
      127.0.0.1 claude.ai
      127.0.0.1 chat.z.ai
      127.0.0.1 www.kimi.com

      # Spyware Blocklist
      127.0.0.1 vortex.data.microsoft.com
    '';
  };
}
