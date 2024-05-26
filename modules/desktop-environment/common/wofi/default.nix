{ pkgs, ... }:

{
  xdg.configFile."wofi/" = {
    source = ./config;
    recursive = true;
  };
  home.packages = with pkgs; [ wofi ];
}
