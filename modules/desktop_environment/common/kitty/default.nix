{ pkgs, ... }:

{
  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
  home.packages = with pkgs; [
    kitty
    (pkgs.writeScriptBin "xkitty" ''
      #!${pkgs.stdenv.shell}
      ${lib.getBin pkgs.kitty}/bin/kitty -o linux_display_server=x11 "$@"
    '')
  ];
}
