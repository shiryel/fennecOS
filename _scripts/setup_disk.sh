###########################################################
# BASED_ON:
# - https://wiki.archlinux.org/title/User:Altercation/Bullet_Proof_Arch_Install#Create_and_mount_BTRFS_subvolumes
# - https://wiki.archlinux.org/title/Btrfs#Compression
# - https://btrfs.readthedocs.io/en/latest/Administration.html?highlight=mount#mount-options
# - https://grahamc.com/blog/erase-your-darlings
#
# Download with: 
# - `curl -L setup-disk.shiryel.com > setup.sh`
#
# Run with:
# - `chmod +x setup.sh`
# - `sudo ./setup.sh /dev/YOUR_DEVICE_HERE`
#
# Wifi Config:
# - `sudo systemctl start wpa_supplicant`
#
# if on `sudo systemctl status wpa_supplicant` you get "rfkill: WLAN soft blocked", try:
# - `rfkill list`
# - `rfkill unblock wlan`
#
# You can use scan / scan_results to see the list of ssid
#
# `wpa_cli`
# > interface wlp2s0
# OK
# > add_network
# 0
# > set_network 0 ssid "myhomenetwork"
# OK
# > set_network 0 psk "mypassword"
# OK
# > set_network 0 key_mgmt WPA-PSK
# OK
# > enable_network 0
# OK
#
###########################################################

#
# Prepare
#

# https://gist.github.com/shiryel/44a24ce9f867e11bd5ddafb69b81c7e1
set -euxo pipefail

if [[ $# -lt 1 ]]; then
  echo "Error: Needs the device, eg: /dev/sda"
  echo "Example: ./setup_disk.sh /dev/sda"
  exit 1
fi

DRIVE=$1

loadkeys us-acentos

#
# Wipe drive (optional)
#

#read -p "Wipe drive with zeroes? (optional) " -n 1 -r
#echo
#if [[ $REPLY =~ ^[Yy]$ ]]
#then
# cryptsetup open --type plain /dev/sdXY container --key-file /dev/urandom
# 
# fdisk -l
# 
# dd if=/dev/zero of=/dev/mapper/container status=progress bs=1M
# 
# cryptsetup close container
#fi

#
# Create disk partitions
#

sgdisk --zap-all $DRIVE

# Note: It's critical to have 20Gb of swap, because the root
# will be a tmpfs with a size of 20G, so computers that
# don't have enough memory can use the swap instead
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
       --new=2:0:-20GiB  --typecode=2:8300 --change-name=2:cryptsystem \
       --new=3:0:0       --typecode=3:8200 --change-name=3:cryptswap \
       $DRIVE

# let the kernel know of the changes
partprobe $DRIVE

#
# Format (luks)
#

# BOOT (maybe change all EFI to efi so windows cant find it easily ??)

sleep 2 # wait for the kernel to update
mkfs.fat -F 32 -n EFI /dev/disk/by-partlabel/EFI

# ROOT

echo "In case of failure, run:"
echo "swapoff -L swap"
echo "cryptsetup close swap"
echo "cryptsetup close system"

# optional
# key size: -s 256
# payload align: --align-payload=8192
# cipher: -c aes-xts-plain64 (for LUKS)
cryptsetup luksFormat /dev/disk/by-partlabel/cryptsystem
cryptsetup open /dev/disk/by-partlabel/cryptsystem system

# SWAP

cryptsetup open --type plain --key-file /dev/urandom /dev/disk/by-partlabel/cryptswap swap
mkswap -L swap /dev/mapper/swap
swapon -L swap

#
#  Format (btrfs)
#

# Temporarily mount our top-level volume for further subvolume creation
mkfs.btrfs --force --label system /dev/mapper/system

# We assume /mnt as the standard mount point
mount -t btrfs LABEL=system /mnt

# CREATE SUBVOLUMES
# (Optional lines: var, etc, keep, games, data, snapshots)

btrfs sub create /mnt/@nix
btrfs sub create /mnt/@var
btrfs sub create /mnt/@etc
btrfs sub create /mnt/@keep
btrfs sub create /mnt/@games
btrfs sub create /mnt/@data
btrfs sub create /mnt/@home
btrfs sub create /mnt/@snapshots

# MOUNT SUBVOLUMES

# remount just the subvolumes under our top-level subvolume (which remains unmounted unless we need to do "surgery" and rollback to a previous system system):
umount -R /mnt

# The variable 'o' in this case is our default set of options for any given filesystem mount, while "o_btrfs" are those plus some options specific to btrfs. 
# The default option "x-mount.mkdir" is a neat trick that allows us to skip the creation of directories for mountpoints (they will be created automatically).
# DOCS: https://btrfs.readthedocs.io/en/latest/Administration.html?highlight=mount#mount-options
o="defaults,x-mount.mkdir"
o_btrfs="$o,ssd,compress=zstd,noatime,discard=async,space_cache"

# NOTE:
# Following: https://grahamc.com/blog/erase-your-darlings
# (Optional lines: /var, /etc, /keep, /.snapshots)

# DESCRIPTION (E.G.) [EXTIMATED SIZE]
# keep root clean (stores in memory) [0~9 MiB]
mount -t tmpfs -o $o tmpfs /mnt
# keeps: nix store [1~99 GiB]
mount -t btrfs -o $o_btrfs,subvol=@nix LABEL=system /mnt/nix
# keeps: logs, configs/caches (clamav, opensnitch, dnscrypt-proxy) [1~9 Gib]
mount -t btrfs -o $o_btrfs,subvol=@var LABEL=system /mnt/var
# keeps: passwords, network and wifi [1~100 MiB]
mount -t btrfs -o $o_btrfs,subvol=@etc LABEL=system /mnt/etc
# to pesist custom config [0~1 GiB]
mount -t btrfs -o $o_btrfs,subvol=@keep LABEL=system /mnt/keep
# to pesist user data [0~1 TiB]
mount -t btrfs -o $o_btrfs,subvol=@games LABEL=system /mnt/keep/games
mount -t btrfs -o $o_btrfs,subvol=@data LABEL=system /mnt/keep/data
# keeps: home configs [1~200 GiB]
mount -t btrfs -o $o_btrfs,subvol=@home LABEL=system /mnt/home
# keeps: home configs [1~200 GiB]
mount -t btrfs -o $o_btrfs,subvol=@snapshots LABEL=system /mnt/.snapshots
# boot
mount -o $o LABEL=EFI /mnt/boot

#
# NixOS Install
#

nixos-generate-config --root /mnt

# Preparing...

# TODO: remove in the next release of nixos
nix-env -iA nixos.nixUnstable
nix-env -iA nixos.git

config_path="/mnt/keep/nixos"
hardware_config_path="$config_path/system/hardware/hardware_config.nix"

git clone https://github.com/shiryel/nixos-dotfiles "$config_path"
cp /mnt/etc/nixos/hardware-configuration.nix "$hardware_config_path"

sed -zi 's/\n  swapDevices =.*];\n//' "$hardware_config_path" # I already have the swap on my flake
rm -rf "$config_path/.git" # because flake is a karen and complains about onership

# the /tmp only uses 50% of ram by default...
# so use this one if you get 3GB OF FUCKING TMPFS AND NOTHING WORKS!
#mount -t tmpfs -o $o,size=16g tmpfs /tmp2
#install="sudo TMPDIR=/tmp2 nixos-install --flake $config_path#generic"
mount -t tmpfs -o $o,remount,size=16G tmpfs /tmp
install="sudo TMPDIR=/tmp nixos-install --flake $config_path#generic"

echo "Run: $install"
