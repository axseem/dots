{
  pkgs,
  inputs,
}: let
  pre-commit-check = inputs.pre-commit-hooks.lib.${pkgs.system}.run {
    src = ../.;
    hooks = {
      alejandra.enable = true;
      check-build = {
        enable = true;
        name = "Check Build";
        entry = "${pkgs.nix}/bin/nix build .#nixosConfigurations.ideapad.config.system.build.toplevel --no-link";
        pass_filenames = false;
      };
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
