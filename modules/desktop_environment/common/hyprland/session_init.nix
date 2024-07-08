# ADAPTED FROM: https://github.com/alebastr/sway-systemd

# Address several issues with DBus activation and systemd user sessions
#
# 1. DBus-activated and systemd services do not share the environment with user
#    login session. In order to make the applications that have GUI or interact
#    with the compositor work as a systemd user service, certain variables must
#    be propagated to the systemd and dbus.
#    Possible (but not exhaustive) list of variables:
#    - DISPLAY - for X11 applications that are started as user session services
#    - WAYLAND_DISPLAY - similarly, this is needed for wayland-native services
#    - I3SOCK/SWAYSOCK - allow services to talk with sway using i3 IPC protocol
#
# 2. `xdg-desktop-portal` requires XDG_CURRENT_DESKTOP to be set in order to
#    select the right implementation for screenshot and screencast portals.
#    With all the numerous ways to start sway, it's not possible to rely on the
#    right value of the XDG_CURRENT_DESKTOP variable within the login session,
#    therefore the script will ensure that it is always set to `sway`.
#
# 3. GUI applications started as a systemd service (or via xdg-autostart-generator)
#    may rely on the XDG_SESSION_TYPE variable to select the backend.
#    Ensure that it is always set to `wayland`.
#
# 4. The common way to autostart a systemd service along with the desktop
#    environment is to add it to a `graphical-session.target`. However, systemd
#    forbids starting the graphical session target directly and encourages use
#    of an environment-specific target units. Therefore, the integration
#    package here provides and uses `sway-session.target` which would bind to
#    the `graphical-session.target`.
#
# 5. Stop the target and unset the variables when the compositor exits.
#
# References:
#  - https://github.com/swaywm/sway/wiki#gtk-applications-take-20-seconds-to-start
#  - https://github.com/emersion/xdg-desktop-portal-wlr/wiki/systemd-user-services,-pam,-and-environment-variables
#  - https://www.freedesktop.org/software/systemd/man/systemd.special.html#graphical-session.target
#  - https://systemd.io/DESKTOP_ENVIRONMENTS/
#
{ pkgs, ... }:
let
  # systemd upstream don't approves the import of the full environment (systemd/systemd#18137), so we explicitly pick them
  variables_from_hyprland = "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE QT_QPA_PLATFORMTHEME";
  variables = "${variables_from_hyprland} DISPLAY";
  # XDG_BACKEND XDG_SESSION_TYPE QT_QPA_PLATFORM QT_PLUGIN_PATH QT_STYLE_OVERRIDE
  target = "hyprland-session.target";
in
pkgs.writeScriptBin "hyprland-session-init" ''
  #!${pkgs.bash}/bin/bash 
  export XDG_CURRENT_DESKTOP=Hyprland
  export XDG_SESSION_DESKTOP="''${XDG_SESSION_DESKTOP:-Hyprland}"
  #export XDG_SESSION_TYPE=wayland
  #export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM}:-wayland"
  #export XDG_BACKEND="''${XDG_BACKEND}:-wayland"

  # Check if another Hyprland session is already active.
  #
  # Ignores all other kinds of parallel or nested sessions
  # (Sway on Gnome/KDE/X11/etc.), as the only way to detect these is to check
  # for (WAYLAND_)?DISPLAY and that is know to be broken on Arch.
  if ${pkgs.systemd}/bin/systemctl --user -q is-active "${target}"; then
      echo "Another session found; refusing to overwrite the variables"
      exit 1
  fi

  # DBus activation environment is independent from systemd. While most of
  # dbus-activated services are already using `SystemdService` directive, some
  # still don't and thus we should set the dbus environment with a separate
  # command.
  ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables}

  # reset failed state of all user units
  ${pkgs.systemd}/bin/systemctl --user reset-failed

  ${pkgs.systemd}/bin/systemctl --user import-environment ${variables}
  ${pkgs.systemd}/bin/systemctl --user start "${target}"
''
