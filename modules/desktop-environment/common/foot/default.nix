{ lib, pkgs, ... }:

let
  foot_config = pkgs.writeText "foot-config" (lib.generators.toINIWithGlobalSection { }
    {
      globalSection = {
        font = "monospace:size=10.5";
      };
      sections = {
        colors = {
          alpha = 0.93;
          background = "1c1c1c";
          foreground = "a4bdbf";
        };
      };
    });
in
{
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/.config/foot/foot.ini 777 - - - ${foot_config}"
  ];
  environment.systemPackages = with pkgs; [ foot ];
}
