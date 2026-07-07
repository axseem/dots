{pkgs, ...}: let
  dwl = pkgs.dwl.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        cp ${../../../config/dwl/config.h} config.h
        patch -p1 < ${../../../config/dwl/hide-edge-borders.patch}
        substituteInPlace config.mk \
          --replace-fail 'XWAYLAND =' 'XWAYLAND = -DXWAYLAND' \
          --replace-fail 'XLIBS =' 'XLIBS = xcb xcb-icccm'
      '';
  });

  start-dwl = pkgs.writeShellScriptBin "start-dwl" ''
    export NIXOS_OZONE_WL=1
    export XCURSOR_SIZE=24
    export HYPRCURSOR_SIZE=24
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_DRM_DEVICES="$(readlink -f /dev/dri/by-path/pci-0000:65:00.0-card)"

    exec ${dwl}/bin/dwl -s '${pkgs.runtimeShell} -lc "
      exec <&-
      swaync &
      wl-paste --type text --watch cliphist store &
      wl-paste --type image --watch cliphist store &
      swayidle -w timeout 180 \"swaylock -f -c 000000\" before-sleep \"swaylock -f -c 000000\" &
      wait
    "'
  '';
in {
  environment.systemPackages = [
    dwl
    start-dwl
    pkgs.xwayland
  ];
}
