{ pkgs, pkgs_unstable, ... }@inputs:

{
  xdg.configFile."imv/config".source = ./config;
  home.packages = with pkgs; [ imv ];
}
