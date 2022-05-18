{ pkgs, pkgs_unstable, ... }@inputs:

{
  xdg.configFile."ranger/" = {
    source = ./config;
    recursive = true;
  };
  home.packages = with pkgs; [ ranger ];
}
