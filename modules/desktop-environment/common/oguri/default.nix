{ pkgs, ... }:

{
  xdg.configFile."oguri/config".source = ./config;
  home.packages = with pkgs; [ oguri ];
}
