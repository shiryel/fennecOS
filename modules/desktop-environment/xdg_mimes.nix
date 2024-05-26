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
  myHM.toMainUser = {

    xdg = {
      enable = true;

      mime.enable = true;

      # make it impossible to programs to add new mimeapps on (3th step)
      dataFile."applications/mimeapps.list".text = "";

      # ~/.config/mimeapps.list
      mimeApps = {
        enable = true;

        defaultApplications = {
          "text/plain" = "neovide.desktop";
          "text/markdown" = "neovide.desktop";
          "text/x-markdown" = "neovide.desktop";
          "text/x-makefile" = "neovide.desktop";
          "image/krita" = "krita.desktop";
          "inode/directory" = "nemo.desktop";
          "application/pdf" = "firefox.desktop";
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
        };
      };
    };
  };
}
