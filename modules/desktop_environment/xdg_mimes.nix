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

{ lib, pkgs, ... }:

let
  mimeapps =
    let
      text = "neovim.desktop;neovide.desktop;nvim.desktop;vim.desktop;";
      images = "imv-dir.desktop;imv.desktop;org.kde.gwenview.desktop;";
      browser = "firefox.desktop;librewolf.desktop;chromium-browser.desktop;";
    in
    pkgs.writeText "mimeapps" (lib.generators.toINI { } {
      "Added Associations" = { };
      "Default Applications" = {
        "text/plain" = text;
        "text/markdown" = text;
        "text/x-markdown" = text;
        "text/x-makefile" = text;
        "image/krita" = "krita.desktop;";
        "image/*" = images;
        "image/webp" = images;
        "image/gif" = images;
        "image/png" = images;
        "image/jpg" = images;
        "image/jpeg" = images;
        "image/svg+xml" = images;
        "image/x-webp" = images;
        "image/x-png" = images;
        "inode/directory" = "nemo.desktop;";
        "application/pdf" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
      };
      "Removed Associations" = { };
    });
in
{
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/.config/mimeapps.list 777 - - - ${mimeapps}"
    "L+ %h/.local/share/applications/mimeapps.list 777 - - - ${mimeapps}"
  ];

  environment.systemPackages = with pkgs; [
    (makeDesktopItem {
      name = "neovim";
      desktopName = "Neovim";
      genericName = "Text Editor";
      type = "Application";
      icon = "nvim";
      terminal = false;
      mimeTypes = [ "text/english" "text/plain" "text/x-makefile" "text/x-c++hdr" "text/x-c++src" "text/x-chdr" "text/x-csrc" "text/x-java" "text/x-moc" "text/x-pascal" "text/x-tcl" "text/x-tex" "application/x-shellscript" "text/x-c" "text/x-c++" ];
      categories = [ "Utility" "TextEditor" ];
      exec = "${lib.getExe foot} -e ${lib.getExe neovim} %F";
    })
  ];
}
