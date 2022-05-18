###########################################################
# This is my main configuration file, its here were
# everything else is called
###########################################################

{ lib, pkgs, pkgs_unstable, ... }@inputs:

with builtins;

{
  imports =
    [
      ./security/kernel.nix
      ./security/network.nix
      ./security/services.nix
      ./security/systemd.nix
      ./virtualisation/default.nix
      ./zsh
      ./audio-visual.nix
      #./bwrap.nix
      ./gaming.nix
      ./hardware.nix
      ./keyboard_moonlander.nix
      ./programs.nix
    ];

  ###############
  # NIX CONFIGS #
  ###############

  # Enable Flakes
  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nix_2_7
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
    '';
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-old --delete-older-than 15d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
  programs.ccache.enable = true;

  ##########
  # MOUNTS #
  ##########

  # use `findmnt -l` to see the fileSystems
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";

  ##################
  # SYSTEM GENERAL #
  ##################

  users =
    let
      # define initial password with: mkpasswd -m sha-512
      pass = "$6$bpTg20o4.y4R9aeP$57cS1O8ctIsWCLRsVSU/AokboxGYScLgRrPymZFu2sNwSoSM/6ZTMZqF1MnA9c6jBUDfNF57oMuYLr40IeNFK/";
    in
    {
      mutableUsers = true;
      # admin
      users.admin = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPassword = pass;
      };
      # normal users
      users.shiryel = {
        isNormalUser = true;
        extraGroups = [ ];
        hashedPassword = pass;
      };
      users.work = {
        isNormalUser = true;
        hashedPassword = pass;
      };
      defaultUserShell = pkgs.zsh;
    };

  documentation = {
    man = {
      enable = true;
      generateCaches = true; # generate the index (needed by tools like apropos)
    };
    dev.enable = true;
    nixos.enable = true;
  };

  environment.systemPackages = with pkgs; [
    man-pages # linux
    man-pages-posix # POSIX
    stdmanpages # GCC C++
    clang-manpages # Clang
  ];

  # Use the systemd-boot EFI boot loader.
  # NOTE: some aditional modules are added were they were due
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time = {
    timeZone = "America/Sao_Paulo";
    hardwareClockInLocalTime = true;
  };

  environment.variables = {
    ###########
    # WAYLAND #
    ###########

    # Use vulkan on wlroot (sway)
    #WLR_RENDERER = "vulkan";

    # The Clutter toolkit has a Wayland backend that allows it to run as a Wayland client. The backend is enabled in the clutter package.
    # To run a Clutter application on Wayland, set CLUTTER_BACKEND=wayland.
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";

    # NEEDS: qt5-wayland
    # To run a Qt 5 application with the Wayland plugin [3], use -platform wayland or QT_QPA_PLATFORM=wayland environment variable. To force the usage of X11 on a Wayland session, use QT_QPA_PLATFORM=xcb. This might be necessary for some proprietary applications that do not use the system's implementation of Qt, such as zoomAUR.
    # if you are using NVIDIA maybe use https://github.com/NVIDIA/egl-wayland/
    QT_QPA_PLATFORM = "wayland";
    # Previously, calculated by the logical DPI using the physical size and resolution of the screen. This works great in most cases, but sometimes the physical dimensions that compositors provide are wrong, which usually results in tiny unreadable fonts. Switched to forcing a DPI of 96 by default (Qt 5.12+)
    #QT_WAYLAND_FORCE_DPI = "physical";
    #QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    GDK_BACKEND = "wayland"; # (default)

    # NEEDS: qt5ct
    # On some compositors, for example sway, Qt applications running natively might have missing functionality. For example, KeepassXC will be unable to minimize to tray. This can be solved by installing qt5ct and setting QT_QPA_PLATFORMTHEME=qt5ct before running the application.
    #QT_QPA_PLATFORMTHEME = "qt5ct";

    # To run a SDL2 application on Wayland, set SDL_VIDEODRIVER=wayland
    # WARNING: Many proprietary games come bundled with old versions of SDL, which don't support Wayland and might break entirely if you set SDL_VIDEODRIVER=wayland. To force the application to run with XWayland, set SDL_VIDEODRIVER=x11.
    SDL_VIDEODRIVER = "wayland";
    SDL_AUDIODRIVER = "pipewire";

    # https://github.com/swaywm/sway/issues/595
    # https://wiki.archlinux.org/title/Java#Gray_window,_applications_not_resizing_with_WM,_menus_immediately_closing
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # https://wiki.archlinux.org/title/Java#Better_font_rendering
    AWT_TOOLKIT = "MToolkit";
    _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true";
    JDK_JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true";

    # More recent versions of Firefox support opting into Wayland via an environment variable
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_WEBRENDER = "1";

    # Ozone Wayland support in Chrome and several Electron apps
    # Still under heavy development and behavior is not always flawless
    NIXOS_OZONE_WL = "1";
  };

  environment.wordlist.enable = true;

  environment.shellAliases = {
    record = "wf-recorder --audio='alsa_output.pci-0000_28_00.3.analog-stereo.monitor'";
    ps = "ps -Ao euser,ruser,suser,fuser,%mem,ppid,comm --forest";

    # Containers
    start-postgres = "podman run -d --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres";
    start-mongodb = "podman run -d --name mongodb -p 27017:27017 mongo";

    # https://github.com/ibraheemdev/modern-unix
    df = "duf";
    htop = "btm --color gruvbox";
    unzip = "unar";

    # PORTS
    ports = "sudo lsof -i -n -P | grep LISTEN";
    ports_all = "sudo lsof -i -n -P";
    # OR:
    # (t)cp (u)dp (p)processes (n)umeric (l)istening
    # > sudo netstat -tupnl
    # > sudo ss -tupnl
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
