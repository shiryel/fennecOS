{ pkgs, ... }:

let
  mangohud_config = pkgs.writeText "mangohud-config" ''
    gpu_stats
    core_load
    vram
    fps
    frametime
    frame_timing
    resolution
    font_size=16

    ################ INTERACTION #################
    toggle_hud=Shift_R+F12
    toggle_logging=Shift_R+F2
    reload_cfg=Shift_R+F4
    upload_log=Shift_R+F3
  '';
in
{
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/.config/MangoHud/MangoHud.conf 777 - - - ${mangohud_config}"
  ];
  environment.systemPackages = with pkgs; [ mangohud ];
}
