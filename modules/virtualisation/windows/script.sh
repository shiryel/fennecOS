################################
# CREATE A DYNAMIC VOLUME WITH:
#
# qemu-img create -f qcow2 -o preallocation=off windows.qcow2 50G
#
################################
# MAN: https://www.qemu.org/docs/master/system/qemu-manpage.html

args=(
	-name "windows10"
	-enable-kvm

  #
  # SECURITY
  #
  # maybe enable resoucecontrol for better performance ?
  -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny
  `if [[ $USER ]]; then
    echo -runas $USER
  fi`
	#-nodefaults # remove all default devices

  #
  # Virtualization Machine
  #

  # > type=pc - Standard PC (Q35 + ICH9, 2009)
  # > vmport=auto - Enables emulation of VMWare IO port
  # > kernel-irqchip=split - KVM in-kernel irqchip support
  # (default is on, but split reduces attack surface)
	-machine q35,type=pc,vmport=auto,accel=kvm,kernel_irqchip=split,hpet=off
  #-accel kvm,kernel-irqchip=split
  #-no-shutdown

  #
  # CPU
  #
  # https://blog.wikichoon.com/2014/07/enabling-hyper-v-enlightenments-with-kvm.html
  # > hv_relaxed disables a Windows sanity check that commonly results in a BSOD when the VM is running on a heavily loaded host (similar to the Linux kernel option no_timer_check, which is automatically enabled when Linux is running on KVM)
	-cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time
	-smp 8,maxcpus=8

  #
  # MEMORY
  #
	#-mem-path /dev/hugepages
	-m 5G,slots=16,maxmem=21G
  -overcommit mem-lock=off

  #
  # GPU
  #
  # BUG: https://bugzilla.redhat.com/show_bug.cgi?id=2048429
  # A VM with 4 assigned devices in a vIOMMU configuration needs to 
  # be able to lock 4x the VM RAM size.
  `if [[ $GPU_PASSTHROUGH ]]; then
	  echo -nographic
	  echo -vga none
    # > x-vga=on - seems to be required if you’re using SeaBIO
	  echo -device vfio-pci,host="$GPU_HOST",x-vga=on,multifunction=on
	  echo -device vfio-pci,host="$GPU_AUDIO_HOST"
  else
    # > -vga qxl - for wayland to work with qemu
    echo -vga qxl
  fi`

  #
  # NETWORK
  #
	#-device virtio-net-pci,netdev=winbr
	#-netdev bridge,id=winbr,br=$BRIDGE_INTERFACE

  #
  # USB 
  #
  # NOTE: for hubs, use dots to separate, eg: hostport=2.1
  -device qemu-xhci,id=xhci

  # Kingston USB storage
  -device usb-host,bus=xhci.0,vendorid=0x0951,productid=0x1666

  # Oculus VR Rift S
  -device usb-host,bus=xhci.0,vendorid=0x2833,productid=0x2052

  #
  # SOUND
  #
  #-device ES1370 # ENSONIQ AudioPCI ES1370

  #
  # MOUSE
  #
  # Show mouse on windows & fixes mouse stutter on android, but it's slower
  -usbdevice tablet

  #
  # VOLUMES
  #
  -hda /keep/data/qemu/windows10.qcow2

  #
  # CDROM
  #
	-cdrom /keep/data/qemu/windows10.iso
)

#XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-:"/run/user/1001"} \
#WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-:"wayland-1"} \
#QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-:"wayland"} \
#GDK_BACKEND=${GDK_BACKEND:-:"wayland"} \
#CLUTTER_BACKEND=${CLUTTER_BACKEND:-:"wayland"} \
#DISPLAY=${DISPLAY:-:0} \
qemu-system-x86_64 "${args[@]}"
