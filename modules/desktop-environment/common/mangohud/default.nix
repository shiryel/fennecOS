{ pkgs, ... }:

{
  xdg.configFile."MangoHud/MangoHud.conf".source = ./MangoHud.conf;
  home.packages = with pkgs; [ mangohud ];
}
