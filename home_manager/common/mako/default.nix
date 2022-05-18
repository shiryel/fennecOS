{ pkgs, pkgs_unstable, ... }@inputs:

{
  xdg.configFile."mako/config".source = ./config;
  home.packages = with pkgs; [ mako ];
}
