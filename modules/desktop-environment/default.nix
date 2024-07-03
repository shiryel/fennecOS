{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.desktopEnvironment;
in
{
  imports = [
    ./gaming.nix
    ./theme.nix
    ./xdg_mimes.nix
    ./common/sway
    ./common/hyprland
    ./common/nemo
    ./common/foot
    ./common/firefox
    ./common/mako
    ./common/mangohud
    ./common/waybar
    ./common/wofi
  ];

  options.myNixOS.desktopEnvironment = {
    enable = mkEnableOption (mdDoc "a full desktop environment");
  };

  config = mkIf cfg.enable {
    ###########
    # Wayland #
    ###########

    services = {
      # https://nixos.wiki/wiki/PipeWire
      # Use `pw-profiler` to profile audio and `pw-top`
      # to see the outputs and quantum/rate
      # quantum/rate*1000 = ms delay
      # eg: 3600/48000*1000 = 75ms
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        wireplumber.enable = true;
      };
    };

    # For configuring dbus-proxy:
    #
    # Use qdbusviewer or...
    #
    # To list all interfaces available on DBUS use:
    # - for session:
    # dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames
    # - for system:
    # dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames
    # To list the methods available on the interface use:
    # dbus-send --session --type=method_call --print-reply --dest=org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Introspectable.Introspect
    # 
    # For configuring Dbus portals:
    # https://flatpak.github.io/xdg-desktop-portal/docs/api-reference.html


    # Run screenshare wayland and containerized apps (better)
    # Needs sway to register on systemd that it started
    xdg.portal = {
      enable = true;
      #wlr.enable = config.myNixOS.desktopEnvironment.sway.enable;

      # check which DE xdg is using with:
      # `XDG_UTILS_DEBUG_LEVEL=5 xdg-open "https://example.com"`
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-hyprland
        # needs GTK_USE_PORTAL=1 per app, because setting it gtksystem wide is unstable
        xdg-desktop-portal-gtk # GNOME, NOTE: this provides the "Open With…" window
        xdg-desktop-portal-kde # KDE
      ];

      # test dbus calls with:
      # nix shell nixpkgs#glib
      # gdbus call --session --dest="org.freedesktop.portal.Desktop" --object-path=/org/freedesktop/portal/desktop --method=org.freedesktop.portal.OpenURI.OpenURI '' 'https://example.com' '{}'

      configPackages = lib.mkForce [ ];
      config = {
        # portals: https://wiki.archlinux.org/title/XDG_Desktop_Portal#List_of_backends_and_interfaces
        common = {
          default = [
            "wlr"
            "gtk"
            "kde"
          ];
          #"org.freedesktop.impl.portal.ScreenCast" = [
          #  "hyprland"
          #];
          #"org.freedesktop.impl.portal.Screenshot" = [
          #  "hyprland"
          #];
        };
      };

      # force apps running FHS or flatpack to use xdg-open by using desktop portals
      # see: https://github.com/NixOS/nixpkgs/issues/160923
      # BUG: BUT, it currently does not work (possible because of my bwrap not having the "share" dirs?)
      # to check if systemd + desktop portals is working use:
      # `systemd-run --user -t gio mime x-scheme-handler/https`
      xdgOpenUsePortal = true;
    };
  };
}
