# https://gist.github.com/shiryel/44a24ce9f867e11bd5ddafb69b81c7e1
set -euxo pipefail

if [[ $# -lt 1 ]]; then
  echo "Error: Needs the device, eg: /dev/sda"
  exit 1
fi

DRIVE=$1

sgdisk --zap-all $DRIVE
sgdisk --clear \
       --new=1:0:0  --typecode=1:8300 --change-name=1:cryptdata \
       $DRIVE

# let the kernel know of the changes
partprobe $DRIVE

#
# Format (luks)
#

cryptsetup luksFormat "${DRIVE}1"
#sudo cryptsetup luksAddKey /dev/sdb1 KEYFILE
cryptsetup open "${DRIVE}1" data

#
#  Format (btrfs)
#

mkfs.btrfs --force --label data /dev/mapper/data

mount -t btrfs /dev/mapper/main-data /keep/mnt

btrfs sub create /keep/mnt/@data
btrfs sub create /keep/mnt/@snapshots
