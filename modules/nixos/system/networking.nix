{pkgs, ...}: {
  networking = {
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
    };

    extraHosts = ''
      # Distraction Blocklist
      127.0.0.1 reddit.com
      127.0.0.1 www.reddit.com
      127.0.0.1 old.reddit.com
      127.0.0.1 instagram.com
      127.0.0.1 www.instagram.com
      127.0.0.1 chess.com
      127.0.0.1 www.chess.com
      127.0.0.1 lichess.org
      127.0.0.1 www.lichess.org
      127.0.0.1 youtube.com
      127.0.0.1 www.youtube.com
      127.0.0.1 tiktok.com
      127.0.0.1 www.tiktok.com

      # Spyware Blocklist
      127.0.0.1 vortex.data.microsoft.com
    '';
  };
}
