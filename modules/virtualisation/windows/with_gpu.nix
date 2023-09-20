# TUTORIALS:
# https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
#
# Check USB with:
# - lsusb 
# (The ID xxxx:yyyy are the vendorid and productid)
#
# Check how much THP (Transparent huge pages) is used globally:
# - grep AnonHugePages /proc/meminfo
#
# REQUIRES:
# - AMD-Vi/Intel VT-d enabled on BIOS
# - IOMMU
# - GPU must support UEFI
#
# LOGS:
# - dmesg | grep -i -e DMAR -e IOMMU
# - journalctl -b -1 -xeu windows.service
# - journalctl -b -1 --reverse

# BUG
# PGD 2743ea067 P4D 2743ea067 PUD 12bf67067 PMD 0 
# #PF: error_code(0x0002) - not-present page
# #PF: supervisor write access in kernel mode
# BUG: kernel NULL pointer dereference, address: 0000000000000050
# amdgpu: probe of 0000:28:00.0 failed with error -17
# amdgpu 0000:28:00.0: amdgpu: amdgpu: finishing device.
# amdgpu 0000:28:00.0: amdgpu: Fatal error during GPU init
# amdgpu 0000:28:00.0: amdgpu: amdgpu_device_ip_init failed
# [drm:amdgpu_device_init.cold [amdgpu]] *ERROR* sw_init of IP block <gmc_v10_0> failed -17
# [drm:amdgpu_ttm_init.cold [amdgpu]] *ERROR* Failed initializing PREEMPT heap.
# [drm:amdgpu_preempt_mgr_init [amdgpu]] *ERROR* Failed to create device file mem_info_preempt_used

{ lib, pkgs, ... }:

{
  # Check if vfio is loaded with:
  # dmesg | grep -i vfio
  boot.kernelModules = [ "kvm-amd" "vfio" "vfio_pci" ];

  boot.kernelParams = [
    # Prevents Linux from touching devices which cannot be passed through
    "iommu=pt" # (pass-through)

    #"intel_iommu=on" # needs to enable if on intel
    "amd_iommu=on" # enabled by default
    #"pcie_aspm=off"
    #"pci=noaer"

    # Unbind EFI video (if any) [1]
    # Alternatively you can unbind with:
    # echo "efi-framebuffer.0" > /sys/bus/platform/devices/efi-framebuffer.0/driver/unbind
    # And bind it back with:
    # echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind
    # [1] - https://www.reddit.com/r/VFIO/comments/ks7ve3/alternative_to_efifboff/
    "video=efifb:off"
  ];

  users.users.kvm-windows = {
    isSystemUser = true;
    group = "kvm-windows";
    description = "Qemu KVM Windows client";
  };
  users.groups.kvm-windows = { };

  security.sudo.extraConfig = ''
    shiryel ALL=NOPASSWD: ${pkgs.systemd}/bin/systemctl start windows.service
    shiryel ALL=NOPASSWD: ${pkgs.systemd}/bin/systemctl stop windows.service
  '';

  systemd.services.windows =
    let
      gpu = "0000:28:00.0";
      gpu_audio = "0000:28:00.1";
    in
    {
      description = "Windows VM with GPU pass-through";
      wantedBy = lib.mkForce [ ];
      script = builtins.readFile ./script.sh;

      path = with pkgs; [ kmod qemu procps ];

      environment = {
        USER = "kvm-windows";
        TMPDIR = "/keep/data/tmp";
        TEMPDIR = "/keep/data/tmp";
        TMP = "/keep/data/tmp";
        TEMP = "/keep/data/tmp";
        DROP_ROOT = "true";
        GPU_PASSTHROUGH = "true";
        GPU_HOST = gpu;
        GPU_AUDIO_HOST = gpu_audio;
      };

      serviceConfig = {
        LimitMEMLOCK = 25000000;
        NoNewPrivileges = true; # never gain new privileges through execve()
        RemoveIPC = true; # System V and POSIX IPC are removed when stopped (only has an effect with DynamicUser)
        ProtectClock = false;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
        ProtectHome = "tmpfs"; # hides /home, /root and /run/user
        BindPaths = "/keep/data/qemu";
        PrivateTmp = true; # makes /tmp and /var/tmp private
        RestrictSUIDSGID = true; # attempts to set the set-user-ID (SUID) or set-group-ID (SGID) bits on files or directories will be denied 
        #Restart = "on-failure";
      };

      # MAN: https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-bus-pci
      # EXAMPLE: https://github.com/joeknock90/Single-GPU-Passthrough
      preStart = ''
                #set -euxo pipefail
                set -x

                pkill sway

                modprobe -i vfio_pci vfio vfio_iommu_type1 vfio_virqfd

                # DISABLE VTCONSOLE
                echo 0 > /sys/class/vtconsole/vtcon0/bind
                echo 0 > /sys/class/vtconsole/vtcon1/bind

                # UNBIND DEVICES
                echo ${gpu} > /sys/bus/pci/devices/${gpu}/driver/unbind
                echo ${gpu_audio} > /sys/bus/pci/devices/${gpu_audio}/driver/unbind

                # OVERRIDE DRIVER WITH VFIO
        	      echo "vfio-pci" > /sys/bus/pci/devices/${gpu}/driver_override
        	      echo "vfio-pci" > /sys/bus/pci/devices/${gpu_audio}/driver_override

                # BIND DEVICES TO VFIO
                echo ${gpu} > /sys/bus/pci/drivers/vfio-pci/bind
                echo ${gpu_audio} > /sys/bus/pci/drivers/vfio-pci/bind
      '';

      # BUG: https://gitlab.freedesktop.org/drm/amd/-/issues/1836
      postStop = ''
                #set -euxo pipefail
                set -x

                # UNBIND VFIO
                echo ${gpu} > /sys/bus/pci/drivers/vfio-pci/unbind
                echo ${gpu_audio} > /sys/bus/pci/drivers/vfio-pci/unbind

                # RESET DRIVER OVERRIDE
        	      echo > /sys/bus/pci/devices/${gpu}/driver_override
        	      echo > /sys/bus/pci/devices/${gpu_audio}/driver_override

                modprobe -i vfio_pci vfio vfio_iommu_type1 vfio_virqfd

                # BIND DEVICES TO ORIGINAL DRIVERS
                echo ${gpu} > /sys/bus/pci/drivers/amdgpu/bind
                echo ${gpu_audio} > /sys/bus/pci/drivers/snd_hda_intel/bind

                # ENABLE VTCONSOLE
                echo 1 > /sys/class/vtconsole/vtcon0/bind
                echo 1 > /sys/class/vtconsole/vtcon1/bind
      '';
    };
}
