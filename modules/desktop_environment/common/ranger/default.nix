{ pkgs, ... }:

{
  xdg.configFile."ranger/" = {
    source = ./config;
    recursive = true;
  };
  home.packages = with pkgs; [ ranger ];
}
