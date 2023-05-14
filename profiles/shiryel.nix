{ config, lib, pkgs, ... }:

with lib;

let
  moonlander_udev = pkgs.writeTextFile {
    name = "moonlander-udev-rules";
    text = ''
      # Teensy rules for the Ergodox EZ
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

      # STM32 rules for the Moonlander and Planck EZ
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", \
        MODE:="0666", \
        SYMLINK+="stm32_dfu"
    '';
    destination = "/lib/udev/rules.d/50-wally.rules";
  };
in
{
  #########
  # Users #
  #########

  fenir = {
    stateVersion = "22.05";
    mainUser = "shiryel";
    desktopEnvironment = {
      enable = true;
      gaming.enable = true;
    };
    hardware = {
      cpu = "amd";
      gpu = "amd";
    };
    #livebook.enable = true;
  };

  fenir.homeManager.toAllUsers = {
    home.enableNixpkgsReleaseCheck = true;
    home.file.".zshrc".text = "# Nothing here";

    programs = {
      git = {
        enable = true;
        extraConfig = {
          init = {
            defaultBranch = "master";
            pull.rebase = true;
            push.default = "current";
          };
        };
        aliases = {
          commend = "commit --amend --no-edit";
          grog = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
          please = "push --force-with-lease";
          root = "rev-parse --show-toplevel";
          # eg: git logme --since 1.day
          # 1.week | 8.hours
          logme = "!git log --pretty=format:\"* %s\" --author `git config user.email`";
        };
        ignores = [ ];
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };

  fenir.homeManager.toMainUser = {
    services.opensnitch-ui.enable = true;
    programs = {
      git = {
        userName = "Shiryel";
        userEmail = "contact@shiryel.com";
        signing = {
          key = "AB634CD93322BD426231F764C4041EA6B32633DE";
          signByDefault = false;
        };
      };
    };
  };

  home-manager.users.work = mkMerge [
    config.fenir.homeManager.toAllUsers
    {
      # automatically calls ssh-add for the ssh-agent
      home.file.".ssh/config".text = "AddKeysToAgent yes"; # no | yes | confirm | ask
    }
  ];

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
        #extraGroups = [ ];
        extraGroups = [ "wheel" ];
        hashedPassword = pass;
      };
      users.work = {
        isNormalUser = true;
        hashedPassword = pass;
      };
      defaultUserShell = pkgs.zsh;
    };

  time = {
    timeZone = "America/Sao_Paulo";
    hardwareClockInLocalTime = true;
  };

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

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  ############
  # Keyboard #
  ############

  services.udev.packages = [ moonlander_udev ];

  # needs plugdev to config keyboard?
  #users.users.shiryel.extraGroups = [ "plugdev" ];

  ############
  # Programs #
  ############

  environment.systemPackages = with pkgs; [
    wally-cli

    # Games
    airshipper

    # Themes
    lxappearance

    # Files
    # In case that the video previews are not working,
    # remove the fail/ on .cache/thumbnails/
    cinnamon.nemo
    libsForQt5.gwenview
    ffmpeg # (ranger, nautilus)
    ffmpegthumbnailer # (ranger, nautilus)
    android-file-transfer
    jmtpfs # (android-file-transfer)

    # workspaces
    shiryel-workspace
    work-workspace

    unzip
    unar # unrar free
    p7zip
    vim
    usbutils

    #
    # Modern unix
    #
    pkgs.kitty
    bottom # htop
    btop
    duf # df
    ncdu # nice du
    procs # ps
    cheat
    tldr
    curl
    wget
    git
    git-lfs
    ranger

    #
    # Linux Admin
    #
    lsof # ls open files
    inetutils
    ntfs3g
    killall
    smartmontools # SMART device tests
    inxi
    # used to debug input devices
    # eg: sudo libinput debug-events
    libinput
    pciutils # lspci
    nix-index # find which package has X file

    # nix
    vulnix
    #nix-doc
    nixdoc
    manix
    #arion

    # Fixes telegram not oppening links on firefox
    (pkgs.makeDesktopItem {
      name = "firefox";
      desktopName = "Firefox";
      genericName = "Web Browser";
      type = "Application";
      icon = "firefox";
      terminal = false;
      mimeTypes = [ "text/html" "text/xml" "application/xhtml+xml" "application/vnd.mozilla.xul+xml" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/ftp" ];
      categories = [ "Network" "WebBrowser" ];
      exec = "firefox %U";
    })

    # Video / Audio
    mpv
    cmus
    pavucontrol
    helvum # pipewire control
    easyeffects # pipewire effects
    yt-dlp

    # Editors
    krita
    #gmic-qt
    #gmic-qt-krita
    godot_4
    blender
    openshot-qt # Video editor
    libreoffice
    #orca-c
    #sonic-pi
    #carla # ardour lmms
    helix

    # Tools
    direnv
    gnumake
    kubectl
    k9s
    postgresql
    dbeaver
    robo3t # mongodb query gui
    tmux
    nixpkgs-review
    #vagrant
    #ansible
    exercism
    pandoc
    nodePackages.npm
    podman-compose
    google-cloud-sdk
    (pkgs.google-cloud-sdk.withExtraComponents [ pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    kubernetes-helm
    archi # archimate

    # Languages
    elixir
    erlang # needed by elixir
    lxqt.lxqt-openssh-askpass # necessary for mix.deps from private repos on work user
    inotify-tools # needed by erlang
    graphviz
    nodejs
    yarn
    rustc
    cargo
    kotlin
    kotlin-language-server

    # GCC
    #gcc
    gdb
    cgdb
    #binutils # linker, assemble, etc
    # This can help in the future: https://github.com/Mic92/nix-ld

    # CLANG
    # XXX: the order of include matters (on flake.nix at least)
    #clang-tools_14
    #clang_14 # clang + clangd
    #lldb_14
    #lld

    # Android
    # NOTE: for android toolchain you need to open and intall it throught android-studio
    # NOTE: to accept the license: https://stackoverflow.com/questions/61993738/flutter-doctor-android-licenses-gives-a-java-error
    #flutter
    android-tools
    #jdk

    #
    # Avoid installing from HM for security reasons
    #
    pinentry
    keepassxc

    #########
    # BWRAP #
    #########
    # Packages that are on overlays/bwrap.nix

    firefox
    librewolf
    chromium
    tor-browser
    tdesktop
    #signal-desktop
    thunderbird
    insomnia
    #phoronix-test-suite
    maigret
    discord
    postman
    #android-studio-canary
    flutter
    prismlauncher
    gnucash

    (lutris.override {
      extraPkgs = pkgs: [ pkgs.openssl ];
      # Fixes: dxvk::DxvkError
      extraLibraries = pkgs:
        let
          gl = config.hardware.opengl;
        in
        [
          pkgs.libjson # FIX: samba json errors
          gl.package
          gl.package32
        ] ++ gl.extraPackages ++ gl.extraPackages32;
    })

    # Test bwrap with the generic-bwrap
    # > wrap
    # Or test it direct using:
    # > bwrap --ro-bind /run /run --ro-bind /bin /bin --ro-bind /etc /etc --ro-bind /nix /nix --ro-bind /sys /sys --ro-bind /var /var --ro-bind /usr /usr --bind /tmp /tmp --dev-bind /dev /dev --unsetenv NIXOS_OZONE_WL --proc /proc discordcanary
    bubblewrap
    generic-bwrap
  ];
}
