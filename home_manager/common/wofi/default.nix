{ pkgs, pkgs_unstable, ... }@inputs:

{
  xdg.configFile."wofi/" = {
    source = ./config;
    recursive = true;
  };
  home.packages = with pkgs; [ wofi ];
}
