final: prev: {
  mangohud = ((prev.mangohud.override {
    libXNVCtrl =
      (final.pkgs.stdenv.mkDerivation {
        name = "stopUsingNvidiaProprietaryShit";
        dontUnpack = true;
        buildCommand = "mkdir $out";
      });
  }).overrideAttrs (old: {
    mesonFlags = old.mesonFlags ++ [ "-Dwith_xnvctrl=disabled" ];
  }));
}
