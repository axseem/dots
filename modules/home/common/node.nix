{pkgs, ...}: let
  mkWrapper = name: pkg: bin:
    pkgs.writeShellScriptBin name ''exec ${pkg}/bin/${bin} "$@"'';
in {
  home.packages = [
    # Default node = latest
    pkgs.nodejs

    # Versioned wrappers (node20, npm20, npx20, etc.)
    (mkWrapper "node20" pkgs.nodejs_20 "node")
    (mkWrapper "node22" pkgs.nodejs_22 "node")
    (mkWrapper "node24" pkgs.nodejs "node")
    (mkWrapper "npm20" pkgs.nodejs_20 "npm")
    (mkWrapper "npm22" pkgs.nodejs_22 "npm")
    (mkWrapper "npm24" pkgs.nodejs "npm")
    (mkWrapper "npx20" pkgs.nodejs_20 "npx")
    (mkWrapper "npx22" pkgs.nodejs_22 "npx")
    (mkWrapper "npx24" pkgs.nodejs "npx")
  ];
}
