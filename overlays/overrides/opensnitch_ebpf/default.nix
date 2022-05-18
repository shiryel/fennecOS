{ lib, ... }:

final: prev: {
  opensnitch_ebpf = with prev;
    (stdenv.mkDerivation rec {
      pname = "opensnitch_ebpf";
      version = "1.5.2";

      sourceRoot = ".";
      srcs = [
        final.opensnitch.src
        final.linuxPackages_latest.kernel.src
      ];

      nativeBuildInputs = [
        pkg-config
        clang-tools
        llvmPackages.clang
        libllvm # llvm-strip
        elfutils
        flex
        bison
        libressl
        bc
        rsync
        python3
        which
        zlib
      ];

      patchPhase = ''
        runHook prePatch

        substituteInPlace source/ebpf_prog/Makefile \
          --replace '/bin/rm' 'rm'

        runHook postPatch
      '';

      configurePhase = ''
        runHook preConfigure

        ebpf="source/ebpf_prog"
        cp $ebpf/opensnitch*.c $ebpf/Makefile linux-*/samples/bpf

        cd linux-*
        ( set +o pipefail; yes "" | make oldconfig )
        make prepare 

        runHook postConfigure
      '';

      buildPhase = ''
        runHook preBuild

        make headers_install
        patchShebangs .
        cd samples/bpf && make

        objdump -h opensnitch*.o
        llvm-strip -g opensnitch*.o

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/etc/opensnitchd
        install -Dm644 opensnitch*.o $out/etc/opensnitchd/

        runHook postInstall
      '';
    });
}
