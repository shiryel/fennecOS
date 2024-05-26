final: prev: {
  ######
  # VR #
  ######

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

  ringracers = with final;
    stdenv.mkDerivation (finalAttrs: {
      pname = "ringracers";
      version = "2.2";

      src = fetchFromGitHub {
        owner = "KartKrewDev";
        repo = "RingRacers";
        rev = "v${finalAttrs.version}";
        hash = "sha256-mvRa2Kc9t++IuAXFnplvLKiUQv4uPohay0NG9kr9UQs=";
      };

      assets = fetchzip {
        name = "${finalAttrs.pname}-${finalAttrs.version}-assets";
        url = "https://github.com/KartKrewDev/RingRacers/releases/download/v${finalAttrs.version}/Dr.Robotnik.s-Ring-Racers-v${finalAttrs.version}-Assets.zip";
        hash = "sha256-Flfrv1vbL8NeN3sxafsHuqPPaxZMgvvohizXefUFoVg=";
        stripRoot = false;
      };

      nativeBuildInputs = [
        cmake
        nasm
        makeWrapper
        copyDesktopItems
      ];

      buildInputs = [
        curl
        game-music-emu
        libpng
        SDL2
        SDL2_mixer
        libvpx
        libyuv
        zlib
      ];

      cmakeFlags = [
        "-DSRB2_ASSET_DIRECTORY=${finalAttrs.assets}"
        "-DGME_INCLUDE_DIR=${game-music-emu}/include"
        "-DSDL2_MIXER_INCLUDE_DIR=${lib.getDev SDL2_mixer}/include/SDL2"
        "-DSDL2_INCLUDE_DIR=${lib.getDev SDL2}/include/SDL2"
      ];

      desktopItems = [
        (makeDesktopItem {
          name = "ringracers";
          exec = "ringracers";
          icon = "ringracers";
          comment = "This is Racing at the Next Level";
          desktopName = "Dr. Robotnik's Ring Racers";
          startupWMClass = ".ringracers-wrapped";
          categories = [ "Game" ];
        })
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 ../srb2.png $out/share/icons/hicolor/256x256/apps/ringracers.png
        install -Dm755 bin/ringracers $out/bin/ringracers
        wrapProgram $out/bin/ringracers \
          --set RINGRACERSWADDIR "${finalAttrs.assets}"
        runHook postInstall
      '';
    });

  #open-composite = prev.stdenv.mkDerivation {
  #  pname = "open-composite";
  #  version = "git";
  #  src = prev.fetchFromGitLab {
  #    owner = "znixian";
  #    repo = "OpenOVR";
  #    rev = "c5256a117f82c04e3f74cc8b3e2eb357f1425270";
  #    sha256 = "sha256-0Es5FuEwu0L43VOYGdNBfxuBehlNx35ymjBUOG/pKLU=";
  #    fetchSubmodules = true;
  #  };

  #  # disable all warnings (they become errors)
  #  NIX_CFLAGS_COMPILE = "-Wno-error -w";

  #  nativeBuildInputs = with prev;[
  #    cmake
  #  ];

  #  buildInputs = with prev; [
  #    vulkan-loader
  #    vulkan-headers
  #    libGLU
  #    python39
  #    xorg.libX11
  #  ];

  #  enableParallelBuilding = true;

  #  installPhase = ''
  #    cp -r . $out
  #  '';
  #};
}
