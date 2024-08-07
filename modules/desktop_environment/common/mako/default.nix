{ pkgs, ... }:

let
  mako_config = pkgs.writeText "mako-config" ''
    # See man 5 mako

    max-visible=2
    sort=-time
    output=HDMI-A-1
    layer=top
    anchor=bottom-right

    font=monospace 10
    background-color=#798BC7F0
    text-color=#d5d6d7
    width=300
    height=100
    margin=10
    padding=5
    border-size=0
    #border-color=#657ABFF0
    border-radius=10
    progress-color=over #5588AAF0
    icons=1
    max-icon-size=64
    icon-path=""
    markup=1
    actions=1
    #format=<b>%s</b>\n%b Default when grouped: (%g) <b>%s</b>\n%b
    default-timeout=10000
    ignore-timeout=0
    group-by=none
  '';
in
{
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/.config/mako/config 777 - - - ${mako_config}"
  ];
  environment.systemPackages = with pkgs; [ mako ];
}
