{ lib, pkgs, ... }:

with lib;

{
  gtk.iconCache.enable = true;

  #########
  # Fonts #
  #########
  # Compare on: https://www.programmingfonts.org/
  # Best fonts:
  # - https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Cousine
  # - https://input.djr.com/
  # - https://www.jetbrains.com/lp/mono/
  # - https://rubjo.github.io/victor-mono/
  # - https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode

  # Font/DPI configuration optimized for HiDPI displays
  #hardware.video.hidpi.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  # real tty font
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
        # Reduce size of NerdFonts:
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/fonts/nerdfonts/shas.nix
        # SymbolsOnly is used to mix fonts like on the waybar
        fonts = [ "NerdFontsSymbolsOnly" "Cousine" ];
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
    # OR
    # fc-list | grep Cousine
    fontconfig.defaultFonts = {
      sansSerif = [ "Source Sans Pro" ];
      serif = [ "Source Serif Pro" ];
      monospace = [ "Cousine Nerd Font" ]; # icons "without mono"
      emoji = [ "Twitter Color Emoji" ];
    };
  };

  ##########
  # Colors #
  ##########

  environment.systemPackages = with pkgs; [
    gnome.dconf-editor
    glib # gsettings
    #gnome.adwaita-icon-theme # default gnome cursors & icons (gtk, tray)

    # dep of qt5.platformTheme = "gnome";
    qgnomeplatform

    # dep of qt5.platformTheme = "gtk2";
    #qtstyleplugins

    #xsettingsd # Some GTK applications running via XWayland, and some Java applications, need an XSettings daemon running in order to pick up the themes and font settings.
  ];

  # ERROR: 
  # "GLib-GIO-ERROR **: 16:24:26.966: No GSettings schemas are installed on the system"
  # Error that crashes android-file-transfer
  # workaround: GTK_THEME="" QT_STYLE_OVERRIDE="" QT_QPA_PLATFORMTHEME="" android-file-transfer
  fenir.homeManager.toMainUser =
    let
      # themes: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/themes
      # icons/cursors: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/icons
      main_theme = "Dracula"; # Adwaita:dark / Mint-Y-Dark
      main_theme_package = pkgs.dracula-theme;
      cursor_theme = "Nordzy-cursors";
      cursor_theme_package = pkgs.nordzy-cursor-theme;
      cursor_size = 24;
      icon_theme = "Tela-purple"; # WhiteSur-dark
      icon_theme_package = pkgs.tela-icon-theme;
      #main_font = "gg sans Normal 12";
      #mono_font = "Ubuntu Mono 13";
    in
    {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          clock-format = "12h";
          gtk-theme = main_theme;
          icon-theme = icon_theme;
          cursor-theme = cursor_theme;
          cursor-size = cursor_size;
          gtk-im-module = "gtk-im-context-simple";
          font-antialiasing = "rgba";
          font-hinting = "full";
          #document-font-name = main_font;
          #font-name = main_font;
          #monospace-font-name = mono_font;
        };
      };

      home.sessionVariables = {
        GTK_THEME = main_theme;
      };

      home.pointerCursor = {
        package = cursor_theme_package;
        name = cursor_theme;
        size = cursor_size;
        # gsettings set org.gnome.desktop.interface cursor-theme "Nordzy-cursors"
        gtk.enable = true; # sets gtk.cursorTheme as this values
      };

      gtk = {
        enable = true;
        # gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
        theme = {
          package = main_theme_package;
          name = main_theme;
        };
        # gsettings set org.gnome.desktop.interface icon-theme "Tela-purple"
        iconTheme = {
          package = icon_theme_package;
          name = icon_theme;
        };
      };

      # https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#Overview
      qt = {
        enable = true;
        style = {
          package = pkgs.adwaita-qt;
          name = "adwaita-dark"; # set QT_STYLE_OVERRIDE
        };
        platformTheme = "gnome"; # set QT_QPA_PLATFORMTHEME
      };
    };
}
