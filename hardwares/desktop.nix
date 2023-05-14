###########################################################
# This file configures MY desktop hardware devices
#
# GENERATING KEYFILE
# - create keyfile (make sure only root can read)
#   openssl genrsa -out $DEST 4096
# - add keyfile 
#   cryptsetup luksAddKey $DEVICE $DEST
#
# TEST:
# - Check disk space
#   df
#
# - Check disk inodes
#   df -Tih
#
# - Check if a process is not holding files open (holding disk space)
#   lsof +L1
#   (check: https://unix.stackexchange.com/questions/68523/find-and-remove-large-files-that-are-open-but-have-been-deleted/141639#141639)
#
# NOTES:
# - Use ‘nixos-generate-config’ to verify if the BOOT section still up-to-date
#
###########################################################

{ lib, modulesPath, ... }:

{
  ###########
  # NETWORK #
  ###########

  networking = {
    hostName = "shiryel";
    extraHosts = ''
      127.0.0.1 mongodb-primary
      127.0.0.1 mongodb-secondary
      127.0.0.1 mongodb-arbiter
    '';
  };

  ########
  # BOOT #
  ########

  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  swapDevices = [
    { device = "/dev/disk/by-partlabel/cryptswap"; randomEncryption.enable = true; }
  ];

  # NOTE: not working with by-partlabel, use by-uuid instead
  # uuid_crypt_system
  boot.initrd.luks.devices."system".device = "/dev/disk/by-uuid/52372cf4-cc12-419b-8a71-9a263a98b3c6";

  fileSystems =
    let
      # Use: lsblk -fs
      uuid_system = "bfd6c923-b9c6-4e4b-8c68-2694e03e90f3";
      uuid_crypt_data = "b8c2455b-7c7d-4dbb-b35f-e34941b711be"; # sdXY
      uuid_data = "f8e053a9-59d1-44ff-85e9-a9f19b853a81"; # dm-X
      uuid_boot = "9375-F7AE";

      ssd = [ "defaults" "ssd" "compress=zstd:3" "noatime" "discard=async" "space_cache" ];
      ssd_exec = ssd ++ [ "nodev" "nosuid" ];
      ssd_noexec = ssd ++ [ "noexec" "nodev" "nosuid" ];
    in
    {
      "/keep/data" = {
        encrypted.enable = true;
        encrypted.label = "main-data";
        encrypted.blkDev = "/dev/disk/by-uuid/${uuid_crypt_data}";
        encrypted.keyFile = "/mnt-root/keep/luks_keyfile";
        device = "/dev/disk/by-uuid/${uuid_data}";
        fsType = "btrfs";
        options = [ "subvol=@data" "defaults" "noexec" "nodev" "nosuid" ];
      };

      "/keep/games" = {
        device = "/dev/disk/by-uuid/${uuid_data}";
        fsType = "btrfs";
        options = [ "subvol=@games" "defaults" "nodev" "nosuid" ];
      };

      "/keep/.data_snapshots" = {
        device = "/dev/disk/by-uuid/${uuid_data}";
        fsType = "btrfs";
        options = [ "subvol=@snapshots" "defaults" "noexec" "nodev" "nosuid"];
      };

      # Max size: Physical RAM + SWAP (Default: 50% of phisycal RAM)
      # https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "defaults" "size=40G" "nodev" "nosuid" "mode=755" ];
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
        neededForBoot = true;
      };
    };
}
