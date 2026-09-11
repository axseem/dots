# axseem's dotfiles

Personal NixOS and macOS (nix-darwin) configuration. Most of the `config` files work on other distros too.

Primary remote is Codeberg ([axseem/dots](https://codeberg.org/axseem/dots)); GitHub mirror: [`axseem/dots`](https://github.com/axseem/dots).

## Structure

- `hosts/`: Host-specific configurations
  - `darwin/`: macOS hosts (e.g., `macbook`)
  - `nixos/`: NixOS hosts (e.g., `ideapad`)
- `modules/`: Modules composed into the hosts; each host imports whole directories through `nix/import-tree.nix`
  - `common/`: Shared modules for both NixOS and Darwin (fonts, nix settings)
  - `darwin/`: macOS-specific modules (homebrew, system, dev-tools)
  - `nixos/`: NixOS-specific modules (desktop, hardware, security, services, system)
  - `home/`: Home Manager modules
    - `common/`: Cross-platform (cli, fish, git, tmux, vscodium)
    - `linux/`: Linux-specific (apps, media, ui, xdg)
- `config/`: Dotfiles symlinked via Home Manager (fish, ghostty, hypr, rofi, etc.)
- `nix/`: Devshell configuration and the module import helper

## Development

Enter the repository environment explicitly with `nix develop`. The repository
does not use `.envrc` because direnv evaluates that file with Bash.

The flake publishes only the host configurations and dev tooling; the modules
are internal and are not a reusable module API.

## Installation

### NixOS

```bash
git clone https://codeberg.org/axseem/dots.git
cd dotfiles
sudo nixos-rebuild switch --flake .#ideapad
```

### macOS

```bash
git clone https://codeberg.org/axseem/dots.git
cd dotfiles
darwin-rebuild switch --flake .#macbook
```
