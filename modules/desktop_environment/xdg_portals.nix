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

{ lib, pkgs, ... }:

{
  # Run screenshare wayland and improves containerized apps
  xdg.portal = {
    enable = true;
    #wlr.enable = config.myNixOS.desktopEnvironment.sway.enable;

    # check which DE xdg is using with:
    # `XDG_UTILS_DEBUG_LEVEL=5 xdg-open "https://example.com"`
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      # needs GTK_USE_PORTAL=1 per app, because setting it gtksystem wide is unstable
      xdg-desktop-portal-gtk # GNOME, NOTE: this provides the "Open With…" window
      #xdg-desktop-portal-kde # KDE
      #xdg-desktop-portal-hyprland
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
    # To check if systemd + desktop portals is working use:
    # `systemd-run --user -t gio mime x-scheme-handler/https`
    xdgOpenUsePortal = true;
  };
}
