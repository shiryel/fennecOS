{ lib, ... }:

with lib;

{
  imports = [
    ./gaming.nix
    ./theme.nix
    ./xdg_mimes.nix
    ./xdg_portals.nix
    ./common/sway
    ./common/hyprland
    ./common/nemo
    ./common/foot
    ./common/firefox
    ./common/mako
    ./common/mangohud
    ./common/waybar
    ./common/wofi
    ./common/zsh
  ];

  options.myNixOS.desktopEnvironment = {
    enable = mkEnableOption (mdDoc "a full desktop environment");
  };
}
