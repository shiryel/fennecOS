{ config, lib, pkgs, ... }:

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

    enableGhostscriptFonts = true;

    enableDefaultPackages = true;
    packages = with pkgs; [
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
    #gnome.dconf-editor
    #glib # gsettings, gio

    #xsettingsd # Some GTK applications running via XWayland, and some Java applications, need an XSettings daemon running in order to pick up the themes and font settings.
  ];

  #programs.dconf.enable = true;

  myHM.toMainUser =
    let
      # themes: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/themes
      # icons/cursors: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/icons

      # DRACULA THEMES: Dracula | Dracula-Solid | Dracula-purple | Dracula-purple-solid
      # OTHER THEMES: Adwaita:dark | Mint-Y-Dark
      main_theme_gtk = "Dracula";
      main_theme_qt = "Dracula-Solid";
      main_theme_package = pkgs.dracula-theme;

      cursor_theme = "Nordzy-cursors";
      cursor_theme_package = pkgs.nordzy-cursor-theme;
      cursor_size = 16;

      icon_theme = "Tela-purple"; # WhiteSur-dark
      icon_theme_package = pkgs.tela-icon-theme;
    in
    {
      #dconf.settings = {
      #  "org/gnome/desktop/interface" = {
      #    gtk-theme = main_theme;
      #    icon-theme = icon_theme;
      #    cursor-theme = cursor_theme;
      #    cursor-size = cursor_size;
      #    gtk-im-module = "gtk-im-context-simple";
      #    font-antialiasing = "rgba";
      #    font-hinting = "full";
      #    #document-font-name = main_font;
      #    #font-name = main_font;
      #    #monospace-font-name = mono_font;
      #  };
      #};

      home.sessionVariables = {
        GTK_THEME = main_theme_gtk;
      };

      home.pointerCursor = {
        name = cursor_theme;
        package = cursor_theme_package;
        size = cursor_size;
        x11.enable = true;
        # gsettings set org.gnome.desktop.interface cursor-theme "Nordzy-cursors"
        gtk.enable = true; # sets gtk.cursorTheme as this values
      };

      # same as "gtk-recent-files-enabled = 0" on gtk3/4
      xdg.configFile."gtk-2.0/gtkfilechooser.ini".text = ''
        [Filechooser Settings]
        StartupMode=cwd
      '';
      #LocationMode=filename-entry
      #ShowHidden=false
      #ShowSizeColumn=true
      #GeometryX=0
      #GeometryY=0
      #GeometryWidth=780
      #GeometryHeight=585
      #SortColumn=name
      #SortOrder=ascending

      # already set `dconf.settings."org/gnome/desktop/interface"` options
      gtk = {
        enable = true;
        # gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
        theme = {
          package = main_theme_package;
          name = main_theme_gtk;
        };

        # gsettings set org.gnome.desktop.interface icon-theme "Tela-purple"
        iconTheme = {
          package = icon_theme_package;
          name = icon_theme;
        };

        cursorTheme = {
          name = cursor_theme;
          package = cursor_theme_package;
        };

        gtk2 = {
          configLocation = "/home/${config.myNixOS.mainUser}/.config/gtk-2.0/gtkrc";
          extraConfig = ''
            gtk-enable-animations=1
            gtk-primary-button-warps-slider=0
            gtk-toolbar-style=3
            gtk-menu-images=1
            gtk-button-images=0
          '';
        };

        # https://docs.gtk.org/gtk3
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-recent-files-enabled = 0;
          gtk-enable-animations = true; # eg: page-up/down scrolling
          gtk-decoration-layout = "icon:minimize,maximize,close";
          gtk-menu-images = true;
          gtk-button-images = false;
          # only available for gtk3, needs libsForQt5.kde-gtk-config
          #gtk-modules = "colorreload-gtk-module:window-decorations-gtk-module";
        };

        # https://docs.gtk.org/gtk4
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-recent-files-enabled = 0;
          gtk-enable-animations = true;
          gtk-decoration-layout = "icon:minimize,maximize,close";
          gtk-menu-images = true;
        };
      };

      # https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#Overview
      qt = {
        enable = true;
        # auto install: qtstyleplugin-kvantum-qt4 libsForQt5.qtstyleplugin-kvantum qt6Packages.qtstyleplugin-kvantum
        style = {
          name = "kvantum"; # set QT_STYLE_OVERRIDE
          package = with pkgs; [
            libsForQt5.qtstyleplugin-kvantum
            qt6Packages.qtstyleplugin-kvantum
          ];
        };
        # auto install: qt5ct
        platformTheme.name = "qtct"; # set QT_QPA_PLATFORMTHEME (defaults to qt5ct)
      };

      # to find compatible themes: nix-locate -r 'kvconfig'
      xdg.configFile = {
        "Kvantum/${main_theme_qt}".source = "${main_theme_package}/share/Kvantum/${main_theme_qt}";
        "Kvantum/kvantum.kvconfig".text = ''
          [General]
          theme=${main_theme_qt}
        '';
      };
    };
}
