{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fenir.desktopEnvironment;
  #homeManager = config.fenir.homeManager;
in
{
  imports = [
    ./gaming.nix
    ./theme.nix
    ./xdg_mimes.nix
    ./common/sway
  ];

  options.fenir.desktopEnvironment = {
    enable = mkEnableOption (mdDoc "a full desktop environment");

    type = mkOption {
      type = types.str;
      default = "sway";
      description = mdDoc "type of desktop environment";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = elem cfg.type [ "sway" ];
        message = ''
          Invalid desktop environment type
        '';
      }
    ];

    fenir.homeManager.toAllUsers = {
      imports = [
        ./common/kitty
        ./common/ranger
      ];
    };

    fenir.homeManager.toMainUser = {
      imports = [
        ./common/alacritty
        ./common/foot
        ./common/firefox
        ./common/imv
        ./common/kitty
        ./common/mako
        ./common/mangohud
        ./common/oguri
        ./common/ranger
        ./common/waybar
        ./common/wofi
      ];
    };

    fenir.desktopEnvironment.sway.enable = cfg.type == "sway";

    ###########
    # Wayland #
    ###########

    services = {
      # https://nixos.wiki/wiki/PipeWire
      # Use `pw-profiler` to profile audio and `pw-top`
      # to see the outputs and quantum/rate
      # quantum/rate*1000 = ms delay
      # eg: 3600/48000*1000 = 75ms
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        wireplumber.enable = true;
      };
    };

    # Run screenshare wayland and containerized apps (better)
    # Needs sway to register on systemd that it started
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        # needs GTK_USE_PORTAL=1 per app
        xdg-desktop-portal-gtk # GNOME
        xdg-desktop-portal-kde # KDE
      ];

      # force apps running FHS or flatpack to use xdg-open
      # see: https://github.com/NixOS/nixpkgs/issues/160923
      xdgOpenUsePortal = true;
    };
  };
}
