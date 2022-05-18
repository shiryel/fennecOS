{ pkgs, pkgs_unstable, ... }@inputs:

{
  xdg.configFile."MangoHud/MangoHud.conf".source = ./MangoHud.conf;
  home.packages = with pkgs; [ mangohud ];
}
