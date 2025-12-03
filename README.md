# axseem's dotfiles

My personal NixOS configuration. Most of the `config` files work on other distros too.

## Structure

- `hosts/`: Host-specific configurations (e.g., `laptop`).
- `modules/`: Reusable NixOS and Home Manager modules.
  - `desktop/`: Desktop environment (Hyprland, etc.).
  - `hardware/`: Hardware-specific config (Audio, Bluetooth, etc.).
  - `home/`: Home Manager modules (UI, Packages, Git, etc.).
  - `system/`: Core system config (Boot, Networking, Users).
- `config/`: Dotfiles symlinked via Home Manager (Fish, Rofi, etc.).
- `nix/`: Devshell and other Nix utilities.

## Modules

This configuration exposes several atomic modules that you can import into your own flake.

### NixOS Modules (`nixosModules`)

- **Desktop**: `hyprland`, `display-manager`
- **Hardware**: `audio`, `bluetooth`, `graphics`, `input`, `power`
- **System**: `boot`, `fonts`, `locale`, `networking`, `nix`
- **Packages**: `dev-tools`, `audio-production`
- **Services**: `system-services`, `virtualization`
- **Security**: `hardening`

### Home Manager Modules (`homeManagerModules`)

- `fish`: Fish shell configuration
- `vscode`: VS Code configuration
- `git`: Basic Git configuration
- `ui`: GTK/QT theming
- `xdg`: XDG config file mappings
- **Package Groups**:
  - `cli`: Command line tools (jq, ffmpeg, etc.)
  - `media`: Media players and editors (vlc, gimp, etc.)
  - `apps`: GUI applications (browsers, chat, etc.)
  - `desktop-utils`: Desktop utilities (file managers, rofi, etc.)

## Usage

You can use this flake as an input in your own configuration to import specific modules.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Add this flake as an input
    axseem.url = "github:axseem/dotfiles";
  };

  outputs = { self, nixpkgs, axseem, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import specific NixOS modules
        axseem.nixosModules.hyprland
        axseem.nixosModules.audio-production
        
        ./configuration.nix
      ];
    };
  };
}
```

## Installation

To apply this configuration to a new system:

1.  Clone the repository:
    ```bash
    git clone https://github.com/axseem/dotfiles.git ~/me/system/nixos
    ```
2.  Enter the directory:
    ```bash
    cd ~/me/system/nixos
    ```
3.  Build and switch:
    ```bash
    sudo nixos-rebuild switch --flake .#laptop
    ```