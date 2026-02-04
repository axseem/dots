{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.llama-cpp;

  # Build llama-cpp from nixpkgs with appropriate backend support
  llamaPackage = pkgs.llama-cpp.override {
    cudaSupport = cfg.backend == "cuda";
    rocmSupport = cfg.backend == "rocm";
    vulkanSupport = cfg.backend == "vulkan";
    # Metal is automatically enabled on Darwin
  };
in {
  options.programs.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp";

    backend = lib.mkOption {
      type = lib.types.enum ["default" "vulkan" "cuda" "rocm"];
      default =
        if pkgs.stdenv.isDarwin
        then "default"
        else "vulkan";
      description = ''
        Backend to use for llama.cpp.
        - default: CPU-only (Metal on Darwin)
        - vulkan: Vulkan acceleration
        - cuda: NVIDIA CUDA (Linux only)
        - rocm: AMD ROCm (x86_64-linux only)
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional llama.cpp packages to install (e.g., python-scripts).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [llamaPackage]
      ++ cfg.extraPackages;
  };
}
