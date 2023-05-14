{ lib, pkgs, modulesPath, ... }:

with builtins;

{
  environment.systemPackages = with pkgs; [
    wpa_supplicant_gui
  ];

  #hardware.sane = {
  #  enable = true;
  #  extraBackends = [ pkgs.hplipWithPlugin ];
  #};

  hardware.name.enable = true;

  users.users.shiryel.extraGroups = [ "scanner" "lp" ];

  networking = {
    hostName = "fen-notebook";
  };

  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  swapDevices = [
    { device = "/dev/disk/by-partlabel/cryptswap"; randomEncryption.enable = true; }
  ];

  # NOTE: not working with by-partlabel, use by-uuid instead
  # uuid_crypt_system
  boot.initrd.luks.devices."system".device = "/dev/disk/by-uuid/8e5eefc2-ff36-4b80-bb36-efbfc2172772";

  fileSystems =
    let
      # Use: lsblk -fs or blkid
      uuid_system = "f3ae655d-6596-46c5-a57a-b4de2336c0a4";
      uuid_boot = "873E-C713";

      ssd = [ "defaults" "ssd" "compress=zstd:3" "noatime" "discard=async" "space_cache" ];
      ssd_exec = ssd ++ [ "nodev" "nosuid" ];
      ssd_noexec = ssd ++ [ "noexec" "nodev" "nosuid" ];
    in
    {
      "/keep/data" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@data" ];
      };

      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "defaults" "size=16G" "nodev" "nosuid" "mode=755" ];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/${uuid_boot}";
        fsType = "vfat";
      };

      "/nix" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@nix" "nodev" ] ++ ssd;
      };

      "/var" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@var" ] ++ ssd_noexec;
      };

      "/etc" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@etc" ] ++ ssd_noexec;
      };

      "/home" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@home" ] ++ (lib.remove "noatime" ssd_exec);
      };

      "/.snapshots" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@snapshots" ] ++ ssd_noexec;
      };

      "/keep" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@keep" ] ++ ssd_noexec;
      };

      "/keep/games" = {
        device = "/dev/disk/by-uuid/${uuid_system}";
        fsType = "btrfs";
        options = [ "subvol=@games" ] ++ ssd_exec;
      };
    };
}

