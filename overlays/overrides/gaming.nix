{ lib, ... }:

final: prev: {

  ######
  # VR #
  ######

  open-composite = prev.stdenv.mkDerivation {
    pname = "open-composite";
    version = "git";
    src = prev.fetchFromGitLab {
      owner = "znixian";
      repo = "OpenOVR";
      rev = "c5256a117f82c04e3f74cc8b3e2eb357f1425270";
      sha256 = "sha256-0Es5FuEwu0L43VOYGdNBfxuBehlNx35ymjBUOG/pKLU=";
      fetchSubmodules = true;
    };

    # disable all warnings (they become errors)
    NIX_CFLAGS_COMPILE = "-Wno-error -w";

    nativeBuildInputs = with prev;[
      cmake
    ];

    buildInputs = with prev; [
      vulkan-loader
      vulkan-headers
      libGLU
      python39
      xorg.libX11
    ];

    enableParallelBuilding = true;

    installPhase = ''
      cp -r . $out
    '';
  };

  monado = (prev.monado.overrideAttrs (old: {
    src = prev.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "monado";
      repo = "monado";
      rev = "9293c628d78ba595918b6b21460fc1df2fbd6f45";
      sha256 = "sha256-oDYyrO45TBl8sTcjk6okMJ5vpqGA08h0XJTcf7grnfo=";
    };
  }));

  # https://github.com/ValveSoftware/SteamVR-for-Linux
  steamvr_udev = prev.writeTextFile {
    name = "60-steam-vr-rules";
    text = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="114d", ATTRS{idProduct}=="8a12", MODE="0660", TAG+="uaccess"
  
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="2c87", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="0306", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="0309", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="030a", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="030b", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="030c", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="030e", MODE="0660", TAG+="uaccess"
      
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="1043", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="1142", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2000", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2010", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2011", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2012", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2021", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2022", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2050", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2101", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2102", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2150", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2300", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2301", MODE="0660", TAG+="uaccess"
      
      SUBSYSTEM=="tty", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2102", MODE="0660", TAG+="uaccess"
    '';
    destination = "/lib/udev/rules.d/60-steam-vr.rules";
  };

  rift_s_udev = prev.writeTextFile {
    name = "70-rift-s-udev-rules";
    text = ''
      # Skip if a remove
      ACTION=="remove", GOTO="xrhardware_end"

      # Oculus Rift S - USB
      ATTRS{idVendor}=="2833", ATTRS{idProduct}=="0051", TAG+="uaccess", ENV{ID_xrhardware}="1"

      # Exit if we didn't find one
      ENV{ID_xrhardware}!="1", GOTO="xrhardware_end"
      
      # XR devices with serial ports aren't modems, modem-manager
      ENV{ID_xrhardware_USBSERIAL_NAME}!="", SUBSYSTEM=="usb", ENV{ID_MM_DEVICE_IGNORE}="1"

      # Make friendly symlinks for XR USB-Serial devices.
      ENV{ID_xrhardware_USBSERIAL_NAME}!="", SUBSYSTEM=="tty", SYMLINK+="ttyUSB.$env{ID_xrhardware_USBSERIAL_NAME}"

      LABEL="xrhardware_end"
    '';
    destination = "/lib/udev/rules.d/70-xrhardware.rules";
  };
}
