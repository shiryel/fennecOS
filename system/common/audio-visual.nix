{ config, pkgs, pkgs_unstable, ... }:

{
  ############
  # Graphics #
  ############
  #
  # NOTE:
  # Hardware Acceleration (HWAccel) is configured on `/system/hardware/*_gpu.nix`
  #

  hardware = {
    # Vulkan / OpenGL
    opengl = {
      enable = true;

      # dri 32/64 support required for STEAM
      driSupport = true;
      driSupport32Bit = true;

      #setLdLibraryPath = true;
    };
  };

  #########
  # Audio #
  #########

  services = {
    # https://nixos.wiki/wiki/PipeWire
    #
    # Use `pw-profiler` to profile audio and
    # `pw-top` to see the outputs and quantum/rate
    # quantum/rate*1000 = ms delay
    # eg: 3600/48000*1000 = 75ms
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  ###############
  # Screenshare #
  ###############

  # Run screenshare wayland and containerized apps (better)
  # Needs sway to register on systemd that it started
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      # needs GTK_USE_PORTAL=1 per app
      xdg-desktop-portal-gtk # GNOME
      #xdg-desktop-portal-kde # KDE
    ];

    # TODO: On nix 23.5 use "xdgOpenUsePortal = true;"
    # to fix discord (depends on https://github.com/NixOS/nixpkgs/pull/197118)
  };

  ##########
  # Themes #
  ##########

  gtk.iconCache.enable = true;

  #########
  # Fonts #
  #########

  # Font/DPI configuration optimized for HiDPI displays
  #hardware.video.hidpi.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;

    enableDefaultFonts = true;
    enableGhostscriptFonts = true;

    fonts = with pkgs; [
      (nerdfonts.override {
        enableWindowsFonts = true;
      })
      carlito
      dejavu_fonts
      fira
      fira-code
      fira-mono
      inconsolata
      inter
      inter-ui
      libertine
      noto-fonts
      noto-fonts-emoji
      noto-fonts-extra
      roboto
      roboto-mono
      roboto-slab
      source-code-pro
      source-sans-pro
      source-serif-pro
      twitter-color-emoji
      corefonts
    ];

    # cd /nix/var/nix/profiles/system/sw/share/X11/fonts
    # fc-query DejaVuSans.ttf | grep '^\s\+family:' | cut -d'"' -f2 
    fontconfig.defaultFonts = {
      sansSerif = [ "Source Sans Pro" ];
      serif = [ "Source Serif Pro" ];
      monospace = [ "Cousine Nerd Font Mono" ];
      emoji = [ "Twitter Color Emoji" ];
    };
  };
}
