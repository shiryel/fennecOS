{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.desktopEnvironment.sway;
in
{
  options.myNixOS.desktopEnvironment.sway = {
    enable = mkEnableOption "Sway with a complete desktop environment";
  };

  config = mkIf cfg.enable {
    security.pam.services.swaylock = { };

    environment.systemPackages = with pkgs; [
      wf-recorder
      wl-clipboard
      libnotify # required to use notify-send
      #glfw-wayland # to make native games work
    ];

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.tmpfiles.users.shiryel.rules =
      let
        sway_cfg = import ./config.nix { inherit lib pkgs; };
      in
      [
        "L+ %h/.config/sway/config - - - - ${sway_cfg}"
        "L+ %h/.config/sway/lockscreen - - - - ${../../imgs/lockscreen.png}"
        "L+ %h/.config/sway/wallpaper - - - - ${../../imgs/wallpaper-hax.jpg}"
      ];
  };
}
