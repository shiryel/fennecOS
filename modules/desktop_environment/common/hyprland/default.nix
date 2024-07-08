{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.desktopEnvironment.hyprland;
in
{
  options.myNixOS.desktopEnvironment.hyprland = {
    enable = mkEnableOption "Hyprland with a complete desktop environment";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      systemd.setPath.enable = false;
      package = pkgs.hyprland.override {
        withSystemd = true;
      };
      xwayland.enable = true;
    };

    systemd.user.tmpfiles.users.shiryel.rules =
      let
        hyprland_cfg = import ./hyprland_conf.nix { inherit lib pkgs; };
      in
      [
        "L+ %h/.config/hypr/hyprland.conf - - - - ${hyprland_cfg}"
        "L+ %h/.config/hypr/lockscreen - - - - ${../../imgs/lockscreen.png}"
        "L+ %h/.config/hypr/wallpaper - - - - ${../../imgs/wallpaper-hax.jpg}"
      ];

    environment.systemPackages = with pkgs; [
      wf-recorder
      wl-clipboard
      libnotify # required to use notify-send
    ];

    # Fix lock not unlocking:
    # https://github.com/nix-community/home-manager/issues/2017
    security.pam.services.swaylock = { };
    services.dbus.enable = true;

    systemd.user.targets.hyprland-session = {
      description = "Hyprland compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ]
        ++ lib.optional config.services.xserver.desktopManager.runXdgAutostartIfNone
        "xdg-desktop-autostart.target";
      after = [ "graphical-session-pre.target" ];
      before = lib.mkIf config.services.xserver.desktopManager.runXdgAutostartIfNone
        [ "xdg-desktop-autostart.target" ];
    };

    #systemd.user.targets.hyprland-session-shutdown = {
    #  description = "Shutdown running Hyprland session";
    #  conflicts = [ "graphical-session.target" "graphical-session-pre.target" "hyprland-session.target" ];
    #  after = [ "graphical-session.target" "graphical-session-pre.target" "sway-session.target" ];
    #};

    systemd.user.targets.tray = {
      description = "Home Manager System Tray";
      requires = [ "graphical-session-pre.target" ];
    };
  };
}
