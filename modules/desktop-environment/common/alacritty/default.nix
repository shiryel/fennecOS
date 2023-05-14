{ pkgs, ... }:

{
  xdg.configFile."alacritty/alacritty.yml".source = ./alacritty.yml;
  home.packages = with pkgs; [
    alacritty
    (pkgs.writeScriptBin "xalacritty" ''
      #!${pkgs.stdenv.shell}
      env -u WAYLAND_DISPLAY ${lib.getBin pkgs.alacritty}/bin/alacritty "$@"
    '')
  ];
}
