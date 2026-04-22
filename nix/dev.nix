{
  pkgs,
  inputs,
}: let
  pre-commit-check = inputs.pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
    src = ../.;
    hooks = {
      alejandra.enable = true;
    };
  };
in {
  formatter = pkgs.writeShellScriptBin "alejandra" ''
    if [ $# -eq 0 ]; then
      ${pkgs.alejandra}/bin/alejandra .
    else
      ${pkgs.alejandra}/bin/alejandra "$@"
    fi
  '';

  checks = {
    inherit pre-commit-check;
  };

  devShells.default = pkgs.mkShell {
    name = "axseem-dots-dev";
    inherit (pre-commit-check) shellHook;
    buildInputs = pre-commit-check.enabledPackages;
  };
}
