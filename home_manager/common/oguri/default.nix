{ pkgs, pkgs_unstable, ... }@inputs:

{
  xdg.configFile."oguri/config".source = ./config;
  home.packages = with pkgs; [ oguri ];
}
