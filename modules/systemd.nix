{ pkgs, ... }:

# systemd-analyze security
# systemd-analyze --user security
#
# https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing

let
  # Allow the sandboxing to be run on user services, eg: ProtectSystem, ProtectHome
  # notice: https://security.stackexchange.com/questions/209529/what-does-enabling-kernel-unprivileged-userns-clone-do
  PrivateUsers = { PrivateUsers = true; };

  # ProtectHome, /home, /root and /run/user
  ProtectHomeAsTmp = { ProtectHome = "tmpfs"; }; # create a tmpfs
  ProtectHomeAsRO = { ProtectHome = "read-only"; }; # make it read-only

  BindXDG = { BindPaths = "/run/user/"; }; # works only with ProtectHomeAsTmp

  ProtectSystem = { ProtectSystem = "full"; }; # makes /boot, /etc, and /usr directories read-only
  PrivateDevices = { PrivateDevices = true; }; # hides /dev mount
  PrivateNetwork = { PrivateNetwork = true; };
  PrivateTmp = { PrivateTmp = true; }; # makes /tmp and /var/tmp private

  # attempts to set the set-user-ID (SUID) or set-group-ID (SGID) bits on files or directories will be denied 
  RestrictSUIDSGID = { RestrictSUIDSGID = true; };
  # makes /sys/fs/cgroup/ read-only
  ProtectControlGroups = { ProtectControlGroups = true; };
  # makes /proc/sys/, /sys/, /proc/sysrq-trigger, /proc/latency_stats, /proc/acpi, /proc/timer_stats, /proc/fs and /proc/irq read-only
  ProtectKernelTunables = { ProtectKernelTunables = true; };

in
{
  # NOTES:
  # - mostly services needs /dev to work (usually error: "status=218/CAPABILITIES")
  # - its not possible to hide home on user services
  systemd.user.services = {
    dconf.serviceConfig = PrivateNetwork; # only_xdg // no_net // restricted;
    # https://en.wikipedia.org/wiki/GVfs#Technical_details
    gvfs-daemon.serviceConfig = { }; # needs /usr for creating trash dir | needs sudo and sys/proc | Can't PrivateNetwork=yes
    gvfs-afc-volume-monitor.enable = false; # serviceConfig = ProtectSystem // PrivateDevices //  only_xdg // no_net // restricted;
    gvfs-goa-volume-monitor.enable = false; # serviceConfig = only_xdg // no_net // restricted;
    gvfs-gphoto2-volume-monitor.enable = false; #serviceConfig = only_xdg // no_net // restricted;
    gvfs-mtp-volume-monitor.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    gvfs-udisks2-volume-monitor.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    gpg-agent.serviceConfig = PrivateNetwork;
    podman.serviceConfig = ProtectKernelTunables;
    opensnitch-ui.serviceConfig = ProtectHomeAsRO; # // PrivateNetwork; # needs dev
    # TODO
    xdg-desktop-portal-gtk.serviceConfig = { }; # Can't PrivateNetwork=yes
    xdg-desktop-portal-wlr.serviceConfig = { }; # Can't PrivateNetwork=yes
    xdg-desktop-portal.serviceConfig = { }; # Can't PrivateNetwork=yes
    xdg-document-portal.serviceConfig = { }; # Can't PrivateNetwork=yes
    # store permissions, like flatpak responses on ~/.local/share/flatpak/db/devices
    xdg-permission-store.serviceConfig = ProtectHomeAsTmp // BindXDG; # Can't PrivateNetwork=yes
    polkit-kde-authentication-agent-1 = {
      description = "polkit-kde-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      } // PrivateNetwork // ProtectSystem // PrivateTmp;
    };
  };

  systemd.services = {
    # network
    NetworkManager-dispatcher.serviceConfig = ProtectHomeAsTmp;
    NetworkManager.serviceConfig = ProtectHomeAsTmp;
    # btrfs
    "btrfs-scrub-.snapshots".serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-etc.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-home.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-keep-data.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-keep-games.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-keep.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-nix.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    btrfs-scrub-var.serviceConfig = PrivateNetwork // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    # miscelaneous
    clamav-daemon.serviceConfig = ProtectHomeAsTmp // ProtectSystem // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    clamav-freshclam.serviceConfig = ProtectHomeAsTmp // ProtectSystem // RestrictSUIDSGID // ProtectControlGroups // ProtectKernelTunables;
    dbus.serviceConfig = ProtectHomeAsRO; # needs network to work and +w to /sys to allow corectrl to work
    emergency.serviceConfig = PrivateNetwork;
    "getty@tty1".serviceConfig = PrivateNetwork;
    logrotate.serviceConfig = PrivateNetwork;
    nix-gc.serviceConfig = PrivateNetwork;
    nix-optimise.serviceConfig = PrivateNetwork;
    nscd.serviceConfig = RestrictSUIDSGID; # already has System=strict Home=ready-only
    # TODO
    #opensnitchd.serviceConfig = ProtectHomeAsTmp;
    podman.serviceConfig = ProtectHomeAsTmp;
    polkit.serviceConfig = ProtectHomeAsTmp // PrivateNetwork;
    #reload-systemd-vconsole-setup.serviceConfig = no_home;
    #rescue.serviceConfig = no_home;
    rtkit-daemon.serviceConfig = ProtectHomeAsTmp // PrivateNetwork;
    # systemd
    #systemd-ask-password-console.serviceConfig = no_net;
    #systemd-ask-password-wall.serviceConfig = no_net;
    #systemd-journald.serviceConfig = no_net;
    #systemd-logind.serviceConfig = no_net;
    #systemd-machined.serviceConfig = no_net;
    #systemd-rfkill.serviceConfig = no_net;
    #systemd-timesyncd.serviceConfig = no_net;
    #systemd-udevd.serviceConfig = no_net;
    #"user@1001".serviceConfig = no_home;
    #"user@1002".serviceConfig = no_home;
    # virtualization
    libvirtd.serviceConfig = ProtectHomeAsTmp // ProtectSystem;
    virtlockd.serviceConfig = ProtectHomeAsTmp // ProtectSystem;
    virtlogd.serviceConfig = ProtectHomeAsTmp // ProtectSystem;
    virtlxcd.serviceConfig = ProtectHomeAsTmp // ProtectSystem;
    virtqemud.serviceConfig = ProtectHomeAsTmp // ProtectSystem;
    virtvboxd.serviceConfig = ProtectHomeAsTmp // ProtectSystem;
  };
}
