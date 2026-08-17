{pkgs, ...}: {
  networking = {
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
    };

    extraHosts = ''
      # Addiction Blocklist
      #127.0.0.1 www.youtube.com
      #127.0.0.1 www.reddit.com
      127.0.0.1 news.ycombinator.com
      127.0.0.1 www.chess.com
      127.0.0.1 www.lichess.org
      127.0.0.1 www.instagram.com
      127.0.0.1 x.com
      127.0.0.1 www.x.com
      127.0.0.1 twitter.com
      127.0.0.1 www.twitter.com
      127.0.0.1 mobile.twitter.com

      # Spyware Blocklist
      127.0.0.1 vortex.data.microsoft.com
    '';
  };
}
