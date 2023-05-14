{ lib, ... }:

final: prev: {
  sway = prev.sway.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ final.vulkan-validation-layers ];
  });

  xwaylandvideobridge = with final; (stdenv.mkDerivation
    {
      pname = "xwaylandvideobridge";
      version = "unstable-2023-06-04";

      src = fetchFromGitLab {
        domain = "invent.kde.org";
        owner = "system";
        repo = "xwaylandvideobridge";
        rev = "75f68526fb3d2a4e1af6644e49dfdc8d9e56985c";
        hash = "sha256-GvutiwF9FxtZ2ehd6dsR3ZY8Mq6/4k1TDpz+xE8SusE=";
      };

      patches = [ ./xwaylandvideobridge.patch ];

      nativeBuildInputs = [
        libsForQt5.qt5.wrapQtAppsHook
        pkg-config
        cmake
        extra-cmake-modules
      ];

      buildInputs = [
        # qt5.qtbase
        # qt5.qtquickcontrols2
        # libsForQt5.kdelibs4support
        libsForQt5.qt5.qtx11extras
        libsForQt5.ki18n
        libsForQt5.kwidgetsaddons
        libsForQt5.knotifications
        libsForQt5.kcoreaddons
        (libsForQt5.kpipewire.overrideAttrs (oldAttrs: {
          version = "unstable-2023-03-28";

          src = fetchFromGitLab {
            domain = "invent.kde.org";
            owner = "plasma";
            repo = "kpipewire";
            #rev = "ed99b94be40bd8c5b7b2a2f17d0622f11b2ab7fb";
            rev = "refs/merge-requests/27/head";
            hash = "sha256-KhmhlH7gaFGrvPaB3voQ57CKutnw5DlLOz7gy/3Mzms=";
          };
        }))
      ];
    });
}
