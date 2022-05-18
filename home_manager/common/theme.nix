{ lib, pkgs, pkgs_unstable, ... }@inputs:

# ERROR: 
# "GLib-GIO-ERROR **: 16:24:26.966: No GSettings schemas are installed on the system"
# Error that crashes android-file-transfer
# workaround: GTK_THEME="" QT_STYLE_OVERRIDE="" QT_QPA_PLATFORMTHEME="" android-file-transfer

let
  #
  # themes: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/themes
  # icons/cursors: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/icons
  #
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
  home.packages = with pkgs; [
    gnome.dconf-editor
    glib # gsettings
    #gnome.adwaita-icon-theme # default gnome cursors & icons (gtk, tray)

    # dep of qt5.platformTheme = "gnome";
    qgnomeplatform

    # dep of qt5.platformTheme = "gtk2";
    #qtstyleplugins

    #xsettingsd # Some GTK applications running via XWayland, and some Java applications, need an XSettings daemon running in order to pick up the themes and font settings.
  ];

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
}
