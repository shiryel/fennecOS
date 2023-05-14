###########################################################
# This file configures XDG
#
# xdg-open tries to open mimes following the list bellow, but notice that in the
# case of the mime not being configured on (1), (2) or (3), xdg-open will try to find
# the mime on the "MimeType=" section of each .desktop under the (4) path
#
# Also note that some apps (eg: Steam) does not look at (2)
#
# - (1) Home: ~/.config/mimeapps.list
# - (2) System: /run/current-system/sw/share/applications/mimeinfo.cache
# - (3) Home (deprecated): ~/.local/share/applications/mimeapps.list
# - (4) Fallback: $XDG_DATA_DIRS/applications
#
# DOCS:
# - To get a list of mimes and apps
#   mimeo --app2mime [appname] and --app2desk [appname]
#   handlr --list
#
# - Mimes: https://github.com/isamert/jaro/blob/master/data/mimeapps.list
#   Load from: echo $XDG_DATA_DIRS
###########################################################

{ pkgs, ... }:

{
  fenir.homeManager.toMainUser = {
    xdg = {
      enable = true;
      # cacheHome = ~/.cache;
      # dataHome = ~/.local/share;
      # stateHome = ~/.local/state;
      systemDirs = {
        config = [ "/etc/xdg" ];
        data =
          # Currently there is some friction between sway and gtk [1]
          # the suggested way to set gtk settings is with gsettings
          # for gsettings to work, we need to tell it where the schemas are
          # using the XDG_DATA_DIR environment variable run at the end of sway config
          # [1] - https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
          let
            schema = pkgs.gsettings-desktop-schemas;
            datadir = "${schema}/share/gsettings-schemas/${schema.name}";
          in
          [ datadir ];
      };
      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME";
        documents = "$HOME/data/docs";
        download = "$HOME/downloads";
        music = "$HOME/data/music";
        pictures = "$HOME/data/images";
        publicShare = "$HOME/public";
        templates = "$HOME/templates";
        videos = "$HOME/data/videos";
        extraConfig = {
          XDG_MISC_DIR = "$HOME/misc";
        };
      };
      mime.enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = [
            "firefox.desktop"
            "librewolf.desktop"
            "chromium-browser.desktop"
          ];
          "x-scheme-handler/https" = [
            "firefox.desktop"
            "librewolf.desktop"
            "chromium-browser.desktop"
          ];
          "application/x-extension-html" = [
            "firefox.desktop"
            "librewolf.desktop"
            "chromium-browser.desktop"
          ];
          "application/pdf" = "firefox.desktop";
          "application/json" = "nvim.desktop";
          "text/*" = "nvim-qt.desktop";
          "audio/*" = "mpv.desktop";
          "video/*" = "mpv.desktop";
          "image/*" = [
            "imv.desktop"
            "firefox.desktop"
            "org.kde.krita.desktop"
          ];
          "inode/directory" = "nemo.desktop";
        };
      };
    };
  };
}
