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
          #tmp = true;
          xdg = false; # if prefs.steam.vr_integration then true else "ro";
          autoBindHome = false;
          dbusProxy = {
            enable = true;
            user = {
              # see: https://github.com/flathub/com.valvesoftware.Steam/blob/beta/com.valvesoftware.Steam.yml
              #owns = [
              #  "com.steampowered.*"
              #];
              talks = [
                "org.freedesktop.Notifications"
                "org.kde.StatusNotifierWatcher"

                "org.freedesktop.portal.Desktop" # always required
                "org.freedesktop.portal.OpenURI"
                # "org.freedesktop.UDisks2" # Used by wine to enumerate disk drives
              ];
            };
          };
          rwBinds =
            [
              # you can run a proton game with the TARGET: explorer.exe
              # to verify if the proton is not accessing the wrong files
              {
                from = "$HOME/bwrap/steam";
                to = "$HOME/";
              }
              "$HOME/.config/MangoHud/MangoHud.conf"
              "$HOME/games/steam_custom_games"
              "/tmp/.X11-unix/X0"
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
              lib.makeSearchPathOutput "steamcompattool" "" [
              # fixes many games, including:
              # - Age of Empires II online out of sync errors
              pkgs.proton-ge-bin
            ]
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
          args = ''-console -nochatui -nofriendsui "$@"''; # -silent
          packages = f: p: with p; {
            # NOTE: wakfu needs to be installed with proton 4.11-13
            steam = steam.override ({ extraLibraries ? pkgs': [ ], ... }: {
              #runtimeOnly = true;
              #extraPkgs = pkgs: with pkgs; [ ];
              extraLibraries = pkgs':
                (extraLibraries pkgs') ++
                  [
                    pkgs'.elfutils
                    pkgs'.gperftools
                  ] ++
                  # Fixes: dxvk::DxvkError
                  (with config.hardware.graphics; if pkgs'.hostPlatform.is64bit
                  then [ package ] ++ extraPackages
                  else [ package32 ] ++ extraPackages32);
            });
          };
        } // steam_common)
        ({
          install = true;
          packages = f: p: with p; {
            gamescope = gamescope;
            BeatSaberModManager = BeatSaberModManager;
            r2modman = r2modman;
            protontricks = protontricks;
            steam-run-external = p.steam-run; # need to be another name to not override the one used by protontricks
          };
        } // steam_common)

        {
          dri = true; # required for vulkan
          net = true;
          xdg = false; # if prefs.steam.vr_integration then true else "ro";
          dbusProxy = {
            enable = true;
            user = {
              talks = [
                "org.freedesktop.Notifications"
                "org.kde.StatusNotifierWatcher"
                # "org.freedesktop.UDisks2" # Used by wine to enumerate disk drives
              ];
            };
          };
          packages = f: p: with p; {
            heroic = heroic;
          };
          rwBinds = [
            "$HOME/games/steam_custom_games"
          ];
          extraConfig = steam_common.extraConfig;
        }
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
      # maximum nice priority allowed to raise to [-20,19] (negative values boost process priority)
      #
      # The 'nice' value should do the same as 'rtprio' but for standard CFQ scheduling
      # It sets the initial process spawned when PAM is setting these limits to that nice vaule, 
      # a normal user can then go to that nice level or higher without needing root to set them [1]
      #
      # The current Linux scheduler gives a program at -1 twice as much CPU power as 
      # a 0, and a program at -2 twice as much as a -1, and so forth. This means that 0.9999046% 
      # of your CPU time will go to the program that's at -20, but some small fraction does go 
      # to the program at 0. The program at 0 will feel like it's running on a 200kHz processor![2][3]
      { domain = "root"; type = "-"; item = "nice"; value = "-20"; }
      # Do not set -20, as the root needs it to be able to fix an unresponsive system[1]
      # TEST: max value with nice --11 echo 1
      { domain = "@users"; type = "-"; item = "nice"; value = "-5"; }
      { domain = "@audio"; type = "-"; item = "nice"; value = "-19"; }

      # the priority to run user process with [-20,19] (negative values boost process priority)
      { domain = "@users"; type = "soft"; item = "priority"; value = "0"; }
      { domain = "@audio"; type = "soft"; item = "priority"; value = "-10"; }

      # Realtime configs
      # Check max with: schedtool -r
      # Check current with: ulimit -a
      { domain = "@users"; type = "-"; item = "rtprio"; value = "10"; }
      { domain = "@audio"; type = "-"; item = "rtprio"; value = "99"; }

      # Number of file descriptors any process owned by the specified domain 
      # can have open at any one time.
      #
      # Certain games needs this value as hight as 8192, or in case of lutris with esync, >=524288 [4][5],
      # but setting this value too high or to unlimited may break some tools like fakeroot [6]
      { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; } # recommended by esync [5]
      { domain = "*"; type = "soft"; item = "nofile"; value = "8192"; } # default 1024
      { domain = "@audio"; type = "soft"; item = "nofile"; value = "65536"; }

      # Memory locked memory is never swappable and remains resident. This value is strictly 
      # controlled because it can be abused by people to starve a system of memory and cause swapping [1]
      { domain = "@audio"; type = "-"; item = "memlock"; value = "524288"; } # default 8192

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
    # [1] - https://serverfault.com/questions/487602/linux-etc-security-limits-conf-explanation
    # [2] - https://wiki.archlinux.org/title/Limits.conf#nice
    # [3] - https://unix.stackexchange.com/questions/334170/is-changing-the-priority-of-a-games-process-to-realtime-bad-for-the-cpu
    # [4] - https://github.com/lutris/docs/blob/master/HowToEsync.md
    # [5] - https://github.com/zfigura/wine/blob/esync/README.esync
    # [6] - https://wiki.archlinux.org/title/Limits.conf#nofile

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
