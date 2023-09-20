#############################################################
# NOTE: Many overrides at `./overlays/overrides/gaming.nix` #
#############################################################

# Some extra workarounds: https://gitlab.com/vr-on-linux/VR-on-Linux

###############################
# VR: MONADO + OPEN-COMPOSITE #
###############################
# https://monado.freedesktop.org/steamvr.html

# We currently use monado + open-composite to make VR work on steam
# without the SteamVR
#
# To do that the bwrap needs to let monado-service ipc be writen on xdg
# and the steam need to have the right env vars configured
#
# Enable VR with `prefs.vr = true` and run steam-vr to run monado-service

########################
# VR: MONADO + STEAMVR #
########################

# To run monado + SteamVR you need to use steam-run to patch the SteamVR 
# drivers:
# steam-run ./.local/share/Steam/steamapps/common/SteamVR/bin/vrpathreg.sh adddriver ${monado}/share/steamvr-monado
#
# SteamVR needs CAP_SYS_NICE+ep to be able to work properly:
# sudo setcap 'cap_sys_nice+ep' /home/shiryel/bwrap/steam/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
# 
# Check with:
# steam-run getcap $HOME/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
#
# Finaly, enable the monado-service(?) with steam-vr and try run a game
# You can check the logs with:
# steam-run cat $HOME/.steam/steam/logs/vrserver.txt
#
# You can unset the CAP_SYS_NICE with:
# sudo setcap -r /home/shiryel/bwrap/steam/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher

########
# UDEV #
########
# https://gitlab.freedesktop.org/monado/utilities/xr-hardware/-/blob/main/70-xrhardware.rules
#
# You need the right udev rules to make your VR work
#

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.desktopEnvironment.gaming;
  mainUser = "shiryel"; #config.myNixOS.mainUser;
in
{
  options.myNixOS.desktopEnvironment.gaming = {
    enable = mkEnableOption ("gaming support");
  };

  config = mkIf cfg.enable {
    # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/configuring-huge-pages_monitoring-and-managing-system-status-and-performance
    #boot.kernelParams = [
    #  "hugepages=1000" # 1000 x 2mb = 2GB
    #];

    hardware.steam-hardware.enable = true; # let controlers work

    services.udev.packages = with pkgs; [
      steamvr_udev
      # rift_s_udev 
    ];

    nixjail.bwrap.profiles =
      let
        steam_common = {
          dev = true; # required for vulkan
          net = true;
          tmp = true;
          xdg = true; # if prefs.steam.vr_integration then true else "ro";
          autoBindHome = false;
          rwBinds =
            [
              # you can run a proton game with the TARGET: explorer.exe
              # to verify if the proton is not accessing the wrong files
              {
                from = "$HOME/bwrap/steam";
                to = "$HOME/";
              }
              "$HOME/.config/MangoHud/MangoHud.conf"
              "/keep/games"
            ];
          extraConfig = [
            # Fix games breaking on wayland
            "--unsetenv WAYLAND_DISPLAY"
            "--unsetenv XDG_SESSION_TYPE"
            "--unsetenv CLUTTER_BACKEND"
            "--unsetenv QT_QPA_PLATFORM"
            "--unsetenv SDL_VIDEODRIVER"
            "--unsetenv SDL_AUDIODRIVER"
            "--unsetenv NIXOS_OZONE_WL"
            # Proton-GE
            "--setenv STEAM_EXTRA_COMPAT_TOOLS_PATHS ${
            pkgs.stdenv.mkDerivation rec {
              pname = "proton-ge-custom";
              version = "GE-Proton8-13";

              src = pkgs.fetchurl {
                url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
                sha256 = "sha256-XdIQYbWqBFidrcWaAxbtkWgKC2G5CFSPNamIhkm/nqo=";
              };

              buildCommand = ''
                mkdir -p $out
                tar -C $out --strip=1 -x -f $src
              '';
            }
          }"
            # CUSTOM VR INTEGRATION
            # "--setenv VR_OVERRIDE ${pkgs.open-composite}"
            # "--setenv XR_RUNTIME_JSON ${pkgs.monado}/share/openxr/1/openxr_monado.json"
            # "--setenv PRESSURE_VESSEL_FILESYSTEMS_RW $XDG_RUNTIME_DIR/monado_comp_ipc"
          ];
        };
      in
      [
        # Steam
        ({
          install = true;
          args = ''-console -nochatui -nofriendsui -silent "$@"'';
          packages = f: p: with p; {
            # NOTE: wakfu needs to be installed with proton 4.11-13
            steam = (steam.override {
              #runtimeOnly = true;
              extraPkgs = pkgs: [ ];
              extraLibraries = pkgs:
                [ pkgs.elfutils ] ++
                  # Fixes: dxvk::DxvkError
                  (with config.hardware.opengl; if pkgs.hostPlatform.is64bit
                  then [ package ] ++ extraPackages
                  else [ package32 ] ++ extraPackages32);
            });
          };
        } // steam_common)
        ({
          install = true;
          packages = f: p: with p; {
            BeatSaberModManager = BeatSaberModManager;
            #protontricks = protontricks;
          };
        } // steam_common)
      ];


    environment.systemPackages = with pkgs; [
      # alternative to steamVR
      # openhmd # (maybe not required with monado)
      # monado

      # Run games faster with:
      # > schedtool -I -p -1 -e steam
      # NOTE: check availability of SCHED_ISO
      schedtool
    ];

    #################
    # OPTIMIZATIONS #
    #################
    # Games does not needs gamemode as it only configures the cpu scaling_governor[1],
    # renice[2], softrealtime[3] and GPU configs[4]
    # [1] - powerManagement.cpuFreqGovernor = "performance";
    #       cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    # [2] - nice -n -1 %command%
    # [3] - only available on kernels with the muqss scheduler (SCHED_ISO) like zen and xenmod
    # [4] - echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level

    powerManagement.cpuFreqGovernor = "performance";

    #
    # LIMITS (man limits.conf)
    #
    # https://wiki.archlinux.org/title/Limits.conf
    # 
    # Check system limits: 
    # - ulimit -a
    # Check the maximum of file descriptors
    # - ulimit -Hn
    # - cat /proc/sys/fs/file-max (for system wide)
    # - cat /proc/sys/fs/nr_open (for system wide)
    # Check number of process per user:
    # - ps h -LA -o user | sort | uniq -c | sort -n
    # 
    security.pam.loginLimits = [
      # Do not set -20, as the root needs it to be able to fix an unresponsive system[1]
      #
      # (not verified) The current Linux scheduler gives a program at -1 twice as much CPU power as 
      # a 0, and a program at -2 twice as much as a -1, and so forth. This means that 0.9999046% 
      # of your CPU time will go to the program that's at -20, but some small fraction does go 
      # to the program at 0. The program at 0 will feel like it's running on a 200kHz processor![2]
      # [1] - https://wiki.archlinux.org/title/Limits.conf#nice
      # [2] - https://unix.stackexchange.com/questions/334170/is-changing-the-priority-of-a-games-process-to-realtime-bad-for-the-cpu
      { domain = mainUser; type = "hard"; item = "nice"; value = "-10"; }
      { domain = mainUser; type = "soft"; item = "nice"; value = "-10"; }
      { domain = mainUser; type = "soft"; item = "priority"; value = "0"; }

      # Number of file descriptors any process owned by the specified domain 
      # can have open at any one time.
      #
      # Certain games needs this value as hight as 8192, but setting this value 
      # too high or to unlimited may break some tools like fakeroot [1]
      # [1] - https://wiki.archlinux.org/title/Limits.conf#nofile
      { domain = "*"; type = "soft"; item = "nofile"; value = "8192"; } # default 1024
      #{ domain = "*"; type = "hard"; item = "nofile"; value = "524288"; }

      # Realtime configs
      # Check with: 
      # - schedtool -r

      #N: SCHED_NORMAL  : prio_min 0, prio_max 0
      #F: SCHED_FIFO    : prio_min 1, prio_max 99
      #R: SCHED_RR      : prio_min 1, prio_max 99
      #B: SCHED_BATCH   : prio_min 0, prio_max 0
      #I: SCHED_ISO     : policy not implemented
      #D: SCHED_IDLEPRIO: prio_min 0, prio_max 0
      { domain = "*"; type = "soft"; item = "rtprio"; value = "50"; }

      # NOTE FOR GAMING:
      # SCHED_ISO was designed to give users a SCHED_RR-similar class. 
      # To quote Con Kolivas: "This is a non-expiring scheduler policy designed to guarantee 
      # a timeslice within a reasonable latency while preventing starvation. Good for gaming, 
      # video at the limits of hardware, video capture etc."
      # 
      # SCHED_ISO is now somewhat deprecated; SCHED_RR is now possible for normal users,
      # albeit to a limited amount only. See newer kernels. (from `man schedtool`)

      # As a short mnemonic rule, each 'F' denotes a set of 4 CPUs
      # (0xF: all 4 CPUs, 0xFF: all 8 CPUs, and so on ...)
      # schedtool -
      # schedtool -a 0,1 -n -10 -e
      # schedtool -a 0xFF -n -10 -e (each F is 4 CPUs)
    ];

    #programs.gamemode = {
    #  enable = true;
    #  settings = {
    #    general = {
    #      renice = 10; # sets renice to -10
    #      softrealtime = "auto"; # needs SCHED_ISO ("auto" will set with >= 4 cpus)
    #      inhibit_screensaver = 0;
    #    };
    #  };
    #};

    #systemd.user.services.gamemoded.serviceConfig = {
    #  # needs SUIDSGID and Devices to work
    #  NoNewPrivileges = true;
    #  ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
    #  ProtectHome = true; # hides /home, /root and /run/user
    #  PrivateNetwork = true;
    #  ProtectControlGroups = true; # makes /sys/fs/cgroup/ read-only
    #  #CapabilityBoundingSet = "CAP_SYS_NICE";
    #};
  };
}
