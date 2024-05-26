final: prev: {
  android-qemu = prev.stdenv.mkDerivation rec {
    pname = "android-qemu";
    version = "v15.8.6-x86_64-OFFICIAL-gapps-20230703";
    src = prev.fetchurl {
      url = "https://downloads.sourceforge.net/project/blissos-x86/Official/BlissOS15/Gapps/Generic/Bliss-${version}.iso";
      hash = "sha256-9eAEgmrznQgI0664FA+bqAzUB5Xr+LUlpxuhuzqm6wk=";
    };

    # https://docs.blissos.org/installation/install-in-a-virtual-machine/install-in-qemu/
    buildCommand = ''
      mkdir -p $out/share/lib
      mkdir -p $out/bin

      cp ${src} $out/share/lib/BlissOS.iso

      cat << EOF > $out/bin/${pname}
        if [[ ! -f android.img ]]; then
          read -p "android.img not found in this directory, would you like to create a new one? [y/N]" answer

          if [[ \$answer == "y" || \$answer == "Y" ]]; then
            qemu-img create -f qcow2 -o preallocation=off android.img 15G
          else
            exit 1
          fi

        fi

        args=(
          -name "BlissOS"
          -enable-kvm

          # Security
          -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny

          # Virtual Machine
          -M q35 

          # Resources (CPU / RAM)
          -m 4G 
          -smp 4 
          -cpu host 
          #-bios ${final.OVMF.fd}/FV/OVMF.fd 

          # Network
          -net nic 
          # https://lists.nongnu.org/archive/html/qemu-discuss/2019-05/msg00029.html
          # https://bugs.launchpad.net/qemu/+bug/1628971
          # ports: 
          # 10022 for ssh
          # 5555 for adb
          # 4000 for host send tcp (to 443 guest)
          # 5000 for host listenner tcp (from 443 guest (usually 10.0.2.100)) NOTE: needs localhost:5000 to be listening
          # use restrict=y to block ports not declared
          #-net user,id=net0,hostfwd=tcp::10022-:22,hostfwd=tcp::5555-:5555,hostfwd=tcp::4000-:443,guestfwd=tcp::443-tcp:127.0.0.1:5000
          -net user,id=net0,hostfwd=tcp::10022-:22,hostfwd=tcp::5555-:5555

          # Devices
          -device virtio-vga-gl 
          -display sdl,gl=on 
          -device qemu-xhci,id=xhci 
          -usb -audiodev pa,id=snd0 
          -device AC97,audiodev=snd0 

          # Drivers / Files
          -drive file=android.img
          -cdrom $out/share/lib/BlissOS.iso
        )

        # https://forum.xda-developers.com/t/enable-adb-root-from-shell.4298567/
        # Command adb root works in development builds only ( i.e. eng and userdebug which have ro.debuggable=1 by default ). So to enable the adb root command on your otherwise rooted device just add the ro.debuggable=1 line to /system/build.prop file. If you want adb shell to start as root by default - then add ro.secure=0 as well.

        echo
        echo "connect via adb with:"
        echo "adb connect localhost:5555"
        echo
        echo "To remount system as r/w: https://docs.blissos.org/knowledgebase/troubleshooting/remount-system-as-read-write/"
        echo
        echo "use ctrl+alt+2 to switch to QEMU console"
        echo "use sendkey alt+f2 to BlissOS console"
        echo

        qemu-kvm "\''${args[@]}"
      EOF

      chmod +x $out/bin/${pname}
    '';
  };
}
