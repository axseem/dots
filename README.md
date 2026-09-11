# axseem's dotfiles

Personal NixOS and macOS (nix-darwin) configuration. Most of the `config` files work on other distros too.

Primary remote is Codeberg ([axseem/dots](https://codeberg.org/axseem/dots)); GitHub mirror: [`axseem/dots`](https://github.com/axseem/dots).

## Structure

- `hosts/`: Host-specific configurations
  - `darwin/`: macOS hosts (e.g., `macbook`)
  - `nixos/`: NixOS hosts (e.g., `ideapad`)
- `modules/`: Modules composed into the hosts; each host imports whole directories through `nix/import-tree.nix`
  - `common/`: Shared modules for both NixOS and Darwin (fonts, nix settings)
  - `darwin/`: macOS-specific modules (homebrew, system)
  - `nixos/`: NixOS-specific modules (desktop, hardware, security, services, system)
  - `home/`: Home Manager modules
    - `common/`: Cross-platform (cli, fish, git, opencode, tmux)
    - `linux/`: Linux-specific (anyrun menus, apps, desktop-utils, media, ui, xdg)
- `config/`: Dotfiles symlinked via Home Manager (fish, foot, ghostty, hypr, imv, swaylock)
- `nix/`: Dev tooling and shared Nix code (`dev.nix`, `import-tree.nix`, `overlay.nix`, Lua runtime)

## Development

Enter the repository environment explicitly with `nix develop`. The repository
does not use `.envrc` because direnv evaluates that file with Bash.

```bash
nix fmt              # format Nix files (alejandra)
nix flake check      # run the pre-commit and Lua automation checks
```

The flake publishes only the host configurations and dev tooling; the modules
are internal and are not a reusable module API.

## Installation

### NixOS

```bash
git clone https://codeberg.org/axseem/dots.git
cd dots
sudo nixos-rebuild switch --flake .#ideapad
```

### macOS

```bash
git clone https://codeberg.org/axseem/dots.git
cd dots
darwin-rebuild switch --flake .#macbook
```
