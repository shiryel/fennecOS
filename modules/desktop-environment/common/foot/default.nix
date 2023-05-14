{ pkgs, ... }:

{
  xdg.configFile."foot/foot.ini".source = ./foot.ini;
  home.packages = with pkgs; [ foot ];
}
