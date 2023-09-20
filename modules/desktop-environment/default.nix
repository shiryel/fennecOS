{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.desktopEnvironment;
in
{
  imports = [
    ./gaming.nix
    ./theme.nix
    ./xdg_mimes.nix
    ./common/sway
    ./common/nemo
  ];

  options.myNixOS.desktopEnvironment = {
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

    myHM.toAllUsers = {
      imports = [
        ./common/kitty
        ./common/ranger
      ];
    };

    myHM.toMainUser = {
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

    myNixOS.desktopEnvironment.sway.enable = cfg.type == "sway";

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

      # check which DE xdg is using with:
      # `XDG_UTILS_DEBUG_LEVEL=5 xdg-open "https://example.com"`
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        # needs GTK_USE_PORTAL=1 per app, because setting it system wide is unstable
        xdg-desktop-portal-gtk # GNOME, NOTE: this provides the "Open With…" window
        xdg-desktop-portal-kde # KDE
      ];

      # force apps running FHS or flatpack to use xdg-open by using desktop portals
      # see: https://github.com/NixOS/nixpkgs/issues/160923
      # BUG: BUT, it currently does not work (possible because of my bwrap not having the "share" dirs?)
      # to check if systemd + desktop portals is working use:
      # `systemd-run --user -t gio mime x-scheme-handler/https`
      xdgOpenUsePortal = false;
    };
  };
}
