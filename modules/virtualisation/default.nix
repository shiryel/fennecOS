###########################################################
# This file configures the virtualisations on the machine
#
# Use "ctrl alt 2" to switch to QEMU console
# Run "sendkey ctrl-alt-f2" to switch tty
#
# How to configure via terminal:
# - Create a image disk:
#   https://qemu-project.gitlab.io/qemu/system/images.html
# - Know your options
#   https://qemu-project.gitlab.io/qemu
#   https://wiki.gentoo.org/wiki/QEMU/Options
# - Connect with adb
#   https://www.android-x86.org/documentation/debug.html
#
# DOCS:
# - https://wiki.nixos.org/wiki/Virt-manager
# - https://www.youtube.com/watch?v=wxxP39cNJOs
# - https://wiki.nixos.org/wiki/Libvirt
# - https://wiki.nixos.org/wiki/OSX-KVM
# - https://discourse.nixos.org/t/networkd-libvirt-bridged-networking-how/11769/4
# - http://ayekat.ch/blog/qemu-networkd
#
###########################################################
# QEMU + ANDROID
#
# CONFIG:
# qemu-img create -f qcow2 -o preallocation=off android.img 10G
# 
# INIT:
# qemu-kvm -net nic -net user,hostfwd=tcp::4444-:5555 -m 3G -smp 2 -hda android.img -cdrom android-x86_64-9.0-r2.iso
# OR
# qemu-kvm -cpu host,+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check -net nic -net user,hostfwd=tcp::10022-:22,hostfwd=tcp::5555-:5555 -m 4G -smp 4 -hda android.img -cdrom android-x86_64-9.0-r2.iso
#
# (remember to activate the usb debug mode)
# adb connect localhost:4444
#
# https://blog.devgenius.io/wireless-debugging-on-android-with-adb-flutter-testing-on-vscode-and-adb-cheat-sheet-9d4825aaa3a8

{ pkgs, ... }:

{
  imports =
    [
      ./windows/simple.nix
    ];

  ##########
  # Podman #
  ##########

  #virtualisation.docker.enable = lib.mkForce false;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  #users.extraGroups.podman.members = [ "shiryel" "work" ];

  ############
  # KVM/QEMU #
  ############

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu.runAsRoot = false;
  };
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ qemu virt-manager ];

  users.extraGroups.qemu-libvirtd.members = [ "shiryel" ];
}
