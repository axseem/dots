{
  pkgs,
  inputs,
}: let
  lua = import ./lua.nix {inherit pkgs;};
  pre-commit-check = inputs.pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
    src = ../.;
    hooks = {
      alejandra.enable = true;
    };
  };
  formatter =
    pkgs.runCommand "alejandra" {
      nativeBuildInputs = [pkgs.makeBinaryWrapper];
    } ''
      mkdir -p "$out/bin"
      makeBinaryWrapper ${lua.interpreter} "$out/bin/alejandra" \
        --add-flags ${./formatter.lua} \
        --set ALEJANDRA ${pkgs.alejandra}/bin/alejandra
    '';
in {
  inherit formatter;

  checks = {
    inherit pre-commit-check;
  };

  devShells.default = pkgs.mkShell {
    name = "axseem-dots-dev";
    inherit (pre-commit-check) shellHook;
    buildInputs = pre-commit-check.enabledPackages ++ [lua.runtime];
  };
}
