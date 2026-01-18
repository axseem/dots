# axseem's dotfiles

Personal NixOS and macOS (nix-darwin) configuration. Most of the `config` files work on other distros too.

## Structure

- `hosts/`: Host-specific configurations
  - `darwin/`: macOS hosts (e.g., `macbook`)
  - `nixos/`: NixOS hosts (e.g., `ideapad`)
- `modules/`: Reusable modules
  - `common/`: Shared modules for both NixOS and Darwin (fonts, nix settings)
  - `darwin/`: macOS-specific modules (homebrew, nix)
  - `nixos/`: NixOS-specific modules (desktop, hardware, security, services, system)
  - `home/`: Home Manager modules
    - `common/`: Cross-platform (cli, fish, git, vscode)
    - `linux/`: Linux-specific (apps, media, ui, xdg)
- `config/`: Dotfiles symlinked via Home Manager (fish, ghostty, hypr, rofi, etc.)
- `nix/`: Devshell configuration

## Modules

This configuration exposes several atomic modules that you can import into your own flake.

### NixOS Modules (`nixosModules`)

- **Common**: `nix`, `fonts`
- **Desktop**: `hyprland`, `display-manager`
- **Hardware**: `audio`, `bluetooth`, `graphics`, `input`, `power`
- **System**: `nix-nixos`, `boot`, `locale`, `networking`
- **Packages**: `dev-tools`, `audio-production`
- **Services**: `system-services`, `virtualization`
- **Security**: `hardening`

### Darwin Modules (`darwinModules`)

- **Common**: `nix`, `fonts`
- **Darwin**: `nix-darwin`, `homebrew`

### Home Manager Modules (`homeManagerModules`)

- **Common** (cross-platform):
  - `fish`: Fish shell configuration
  - `vscode`: VS Code configuration
  - `git`: Git configuration
  - `cli`: Command line tools
- **Linux**:
  - `ui`: GTK/QT theming
  - `xdg`: XDG config file mappings
  - `cli-linux`: Linux-specific CLI tools
  - `media`: Media players and editors
  - `apps`: GUI applications
  - `desktop-utils`: Desktop utilities (file managers, rofi, etc.)

## Usage

You can use this flake as an input in your own configuration to import specific modules.

### NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    axseem.url = "github:axseem/dotfiles";
  };

  outputs = { nixpkgs, axseem, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        axseem.nixosModules.hyprland
        axseem.nixosModules.audio
        ./configuration.nix
      ];
    };
  };
}
```

### macOS (nix-darwin)

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    axseem.url = "github:axseem/dotfiles";
  };

  outputs = { nixpkgs, nix-darwin, axseem, ... }: {
    darwinConfigurations.my-mac = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        axseem.darwinModules.homebrew
        axseem.darwinModules.fonts
        ./configuration.nix
      ];
    };
  };
}
```

## Installation

### NixOS

```bash
git clone https://github.com/axseem/dotfiles.git
cd dotfiles
sudo nixos-rebuild switch --flake .#ideapad
```

### macOS

```bash
git clone https://github.com/axseem/dotfiles.git
cd dotfiles
darwin-rebuild switch --flake .#macbook
```