###########################################################
# This file configures your moonlander keyboard
#
# NOTES:
# - Needs user with plugdev to config keyboard
#
###########################################################

{ pkgs, ... }:

let
  moonlander_udev = pkgs.writeTextFile {
    name = "moonlander-udev-rules";
    text = ''
      # Teensy rules for the Ergodox EZ
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

      # STM32 rules for the Moonlander and Planck EZ
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", \
        MODE:="0666", \
        SYMLINK+="stm32_dfu"
    '';
    destination = "/lib/udev/rules.d/50-wally.rules";
  };
in
{
  services.udev.packages = [ moonlander_udev ];

  #users.users.shiryel.extraGroups = [ "plugdev" ];

  environment.systemPackages = with pkgs; [
    wally-cli
  ];
}
