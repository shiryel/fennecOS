{ config, lib, pkgs, pkgs_unstable, channels, ... }:

# systemd-analyze security
# systemd-analyze --user security
#
# https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing

let
  only_xdg = {
    ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
    ProtectHome = "tmpfs"; # hides /home, /root and /run/user
    BindPaths = "/run/user/";
    PrivateTmp = true; # makes /tmp and /var/tmp private
  };
  no_home = {
    ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
    #ProtectSystem = true; # makes /usr, /boot and /efi read-only
    ProtectHome = true; # hides /home, /root and /run/user
    #PrivateTmp = true; # makes /tmp and /var/tmp private (breaks opensnitchd)
  };
  no_dev = { PrivateDevices = true; }; # hides /dev mount
  no_net = { PrivateNetwork = true; };
  protected = {
    #ProtectControlGroups = true; # makes /sys/fs/cgroup/ read-only
    #ProtectKernelTunables = true; # makes /proc/sys/, /sys/, /proc/sysrq-trigger, /proc/latency_stats, /proc/acpi, /proc/timer_stats, /proc/fs and /proc/irq read-only
    #RestrictSUIDSGID = true; # attempts to set the set-user-ID (SUID) or set-group-ID (SGID) bits on files or directories will be denied 
  };
  restricted = {
    ProtectControlGroups = true; # makes /sys/fs/cgroup/ read-only
    ProtectKernelTunables = true; # makes /proc/sys/, /sys/, /proc/sysrq-trigger, /proc/latency_stats, /proc/acpi, /proc/timer_stats, /proc/fs and /proc/irq read-only
    RestrictSUIDSGID = true; # attempts to set the set-user-ID (SUID) or set-group-ID (SGID) bits on files or directories will be denied 
  };
in
{
  # NOTES:
  # - mostly services needs /dev to work (usually error: "status=218/CAPABILITIES")
  systemd.user.services = {
    dbus.serviceConfig = only_xdg // no_net // restricted;
    dconf.serviceConfig = only_xdg // no_net // restricted;
    gvfs-daemon.serviceConfig = only_xdg; # needs sudo and sys/proc | Can't PrivateNetwork=yes
    gvfs-afc-volume-monitor.serviceConfig = only_xdg // no_net // restricted;
    gvfs-goa-volume-monitor.serviceConfig = only_xdg // no_net // restricted;
    gvfs-gphoto2-volume-monitor.serviceConfig = only_xdg // no_net // restricted;
    gvfs-mtp-volume-monitor.serviceConfig = only_xdg // no_net // restricted;
    gvfs-udisks2-volume-monitor.serviceConfig = only_xdg // no_net // restricted;
    gpg-agent.serviceConfig = only_xdg // no_net // restricted;
    podman.serviceConfig = only_xdg // restricted;
    opensnitch-ui.serviceConfig = only_xdg // no_net // restricted; # needs dev, even without any error
    xdg-desktop-portal-gtk.serviceConfig = only_xdg // restricted; # Can't PrivateNetwork=yes
    xdg-desktop-portal-wlr.serviceConfig = only_xdg // restricted; # Can't PrivateNetwork=yes
    xdg-desktop-portal.serviceConfig = only_xdg // restricted; # Can't PrivateNetwork=yes
    xdg-document-portal.serviceConfig = only_xdg; # Can't PrivateNetwork=yes
    xdg-permission-store.serviceConfig = only_xdg // restricted; # Can't PrivateNetwork=yes
  };

  systemd.services = {
    # network
    NetworkManager-dispatcher.serviceConfig = no_home;
    NetworkManager.serviceConfig = no_home;
    # btrfs
    "btrfs-scrub-.snapshots".serviceConfig = no_net // restricted;
    btrfs-scrub-etc.serviceConfig = no_net // restricted;
    btrfs-scrub-home.serviceConfig = no_net // restricted;
    btrfs-scrub-keep-data.serviceConfig = no_net // restricted;
    btrfs-scrub-keep-games.serviceConfig = no_net // restricted;
    btrfs-scrub-keep.serviceConfig = no_net // restricted;
    btrfs-scrub-nix.serviceConfig = no_net // restricted;
    btrfs-scrub-var.serviceConfig = no_net // restricted;
    # miscelaneous
    #clamav-daemon.serviceConfig = no_home // restricted;
    dbus.serviceConfig = no_home // restricted; # Can't PrivateNetwork=yes
    emergency.serviceConfig = no_net;
    "getty@tty1".serviceConfig = no_net;
    logrotate.serviceConfig = no_home // no_net;
    nix-gc.serviceConfig = no_net;
    nix-optimise.serviceConfig = no_net;
    nscd.serviceConfig = restricted; # already has System=strict Home=ready-only
    opensnitchd.serviceConfig = no_home;
    podman.serviceConfig = restricted;
    polkit.serviceConfig = no_home // no_net;
    #reload-systemd-vconsole-setup.serviceConfig = no_home;
    #rescue.serviceConfig = no_home;
    rtkit-daemon.serviceConfig = no_home // no_net;
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
    libvirtd.serviceConfig = no_home // restricted;
    virtlockd.serviceConfig = no_home // restricted;
    virtlogd.serviceConfig = no_home // restricted;
    virtlxcd.serviceConfig = no_home // restricted;
    virtqemud.serviceConfig = no_home // restricted;
    virtvboxd.serviceConfig = no_home // restricted;
  };
}
