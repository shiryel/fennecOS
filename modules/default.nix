{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS;
in
{
  imports = [
    ./desktop-environment
    ./zsh
    ./security
    ./virtualisation
    ./hardware.nix
    ./home-manager.nix
  ];

  options.myNixOS = {
    stateVersion = mkOption {
      type = types.str;
      example = "22.05";
      description = "The `stateVersion` config for nixos and home-manager";
    };

    mainUser = mkOption {
      type = types.str;
      example = "shiryel";
      description = "Main user of the system";
    };
  };

  config = {
    myHM.toAllUsers.home.stateVersion = cfg.stateVersion;
    system.stateVersion = cfg.stateVersion;

    ###############
    # Nix Configs #
    ###############

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
        options = "--delete-old --delete-older-than 7d";
      };
      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };

    programs.ccache.enable = true;
    environment.wordlist.enable = true;

    ##########
    # Mounts #
    ##########

    # use `findmnt -l` to see the fileSystems
    services.btrfs.autoScrub.enable = true;
    services.btrfs.autoScrub.interval = "monthly";

    # Use the systemd-boot EFI boot loader.
    # NOTE: some aditional modules are added were they were due
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    ########
    # Docs #
    ########

    documentation = {
      man = {
        enable = true;
        generateCaches = false; # generate the index (needed by tools like apropos)
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

    ############
    # PROGRAMS #
    ############

    programs = {
      # Zsh global config (super-seeded by home-manager)
      # This mostly impacts the root/admin users

      # We use the bwrap version instead
      neovim.enable = lib.mkForce false;

      wireshark.enable = true;
      wireshark.package = pkgs.wireshark;

      # Some programs need SUID wrappers, can be configured further or 
      # are started in user sessions.
      mtr.enable = true;
    };

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
  };
}
