{ lib, pkgs, ... }:

{
  #users.users.kvm-windows = {
  #  isSystemUser = true;
  #  group = "kvm-windows";
  #  description = "Qemu KVM Windows client";
  #};
  #users.groups.kvm-windows = { };

  systemd.user.services.windows =
    {
      description = "Simple windows VM";
      wants = [ "graphical-session.target" ];
      wantedBy = lib.mkForce [ ];
      script = builtins.readFile ./script.sh;

      environment = {
        DROP_ROOT = "true";
      };

      path = with pkgs; [ kmod qemu procps ];

      serviceConfig = {
        LimitMEMLOCK = 25000000;
        #NoNewPrivileges = true; # never gain new privileges through execve()
        #RemoveIPC = true; # System V and POSIX IPC are removed when stopped (only has an effect with DynamicUser)
        #ProtectClock = false;
        #ProtectKernelModules = true;
        #ProtectControlGroups = true;
        #ProtectKernelLogs = true;
        #ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
        #BindPaths = "/keep/data/qemu";
        #ProtectHome = "tmpfs"; # required by BindPaths
        #PrivateUsers = true; # required by ProtectHome
        #PrivateTmp = true; # makes /tmp and /var/tmp private
        #RestrictSUIDSGID = true; # attempts to set the set-user-ID (SUID) or set-group-ID (SGID) bits on files or directories will be denied 
      };
    };
}
