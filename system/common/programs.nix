{ config, lib, pkgs, pkgs_unstable, ... }:

{
  ######################
  # HOME MANAGER FIXES #
  ######################
  # System wide configs to make stuf work on Home Manager
  #

  # Fix swaylock not unlocking:
  # https://github.com/nix-community/home-manager/issues/2017
  security.pam.services.swaylock = { };

  #################
  # GENERAL FIXES #
  #################

  # Fixes android file transfer, nautilus and 
  # https://wiki.archlinux.org/title/Java#Java_applications_cannot_open_external_links
  services.gvfs.enable = true;

  # pdf preview support for gnome apps (eg, nautilus, nemo)
  programs.evince.enable = true;

  # lets android devices connect
  services.udev.packages = [ pkgs.android-udev-rules ];
  users.groups.adbusers = { }; # To enable device as a user device if found (add an "android" SYMLINK)

  ############
  # PROGRAMS #
  ############

  programs = {
    # Zsh global config (super-seeded by home-manager)
    # This mostly impacts the root/admin users

    # We use the bwrap version instead
    neovim.enable = lib.mkForce false;

    #wireshark.enable = true;
    #wireshark.package = pkgs.wireshark;

    # Some programs need SUID wrappers, can be configured further or 
    # are started in user sessions.
    mtr.enable = true;
  };

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  environment.systemPackages = with pkgs; [
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
    kitty
    bottom # htop
    glances # top
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
    pkgs_unstable.tor-browser
    pkgs_unstable.tdesktop
    #signal-desktop
    thunderbird
    pkgs_unstable.insomnia
    #phoronix-test-suite
    maigret
    pkgs_unstable.discord
    postman
    #android-studio-canary
    flutter
    prismlauncher

    (gnucash.overrideAttrs (old: rec {
      pname = "gnucash";
      version = "4.13";

      src = fetchurl {
        url = "https://github.com/Gnucash/gnucash/releases/download/${version}/${pname}-${version}.tar.bz2";
        hash = "sha256-QBoVgIZjXqF/uxRTJVWFNyiaodJNAi98MxfhLz2r2Oc=";
      };
    }))

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

  #services.searx = {
  #  enable = true;
  #  settings = {
  #    server.port = 8888;
  #    server.bind_address = "127.0.0.1";
  #    server.secret_key = (
  #      # Not the bests of the secrets, but this is only for the API
  #      # and as much the firewall is ON this is not a concern,
  #      # unfortunately, its required by Searx
  #      toString (lib.trivial.oldestSupportedRelease / 3.0) +
  #      toString (lib.trivial.oldestSupportedRelease / 0.3) +
  #      lib.version
  #    );
  #  };
  #};

}
