{pkgs, ...}: let
  mkWrapper = name: pkg: bin:
    pkgs.writeShellScriptBin name ''exec ${pkg}/bin/${bin} "$@"'';
in {
  home.packages = [
    # Default node = latest
    pkgs.nodejs

    # Versioned wrappers (node22, node24, etc.)
    (mkWrapper "node22" pkgs.nodejs_22 "node")
    (mkWrapper "node24" pkgs.nodejs "node")
    (mkWrapper "npm22" pkgs.nodejs_22 "npm")
    (mkWrapper "npm24" pkgs.nodejs "npm")
    (mkWrapper "npx22" pkgs.nodejs_22 "npx")
    (mkWrapper "npx24" pkgs.nodejs "npx")
  ];
}
