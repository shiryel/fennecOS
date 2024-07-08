{ pkgs, ... }:

let
  wofi_config = pkgs.writeText "wofi-config" (builtins.readFile ./config/config);
  wofi_style = pkgs.writeText "wofi-style" (builtins.readFile ./config/style.css);
in
{
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/.config/wofi/config 777 - - - ${wofi_config}"
    "L+ %h/.config/wofi/style.css 777 - - - ${wofi_style}"
  ];
  environment.systemPackages = with pkgs; [ wofi ];
}
