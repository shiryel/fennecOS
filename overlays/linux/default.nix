final: prev: {
  #linuxPackages_latest = prev.linuxPackages_latest.extend (kfinal: kprev: {
  #  kernel = kprev.kernel.override {
  #    # https://www.kernelconfig.io
  #    # https://cateee.net/lkddb/web-lkddb/
  #    structuredExtraConfig = with lib.kernel; {
  #      # https://www.kernel.org/doc/html/next/admin-guide/mm/multigen_lru.html
  #      LRU_GEN = yes;
  #      LRU_GEN_ENABLED = yes;

  #      # adds -O2 and -Os to KBUILD_CFLAGS and KBUILD_RUSTFLAGS
  #      CC_OPTIMIZE_FOR_PERFORMANCE = yes;

  #      # SCHED_MUQSS = yes;
  #    };

  #    #####################
  #    # Compile as native #
  #    #####################
  #    # Check with:
  #    # ps -ALf | grep cc | nvim
  #    # ps -ALf | grep native

  #    kernelPatches = [
  #      {
  #        name = "graysky2_kernel_compiler_patch";
  #        patch = ./config.patch;
  #        # kernelPatchs uses `extraStructuredConfig` instead
  #        # of `structuredExtraConfig`
  #        extraStructuredConfig = with lib.kernel; {
  #          MNATIVE_AMD = yes;
  #        };
  #      }
  #    ];

  #    # Instead of using graysky2 patch, we can also try to
  #    # use env vars or the `extraMakeFlags` with the flags
  #    # documented here:
  #    # https://github.com/torvalds/linux/blob/v6.1/Makefile#L562
  #    # https://docs.kernel.org/kbuild/makefiles.html
  #    #
  #    # Compiler options for userspace programs:
  #    # https://docs.kernel.org/kbuild/makefiles.html#controlling-compiler-options-for-userspace-programs
  #    # USERCFLAGS
  #    #
  #    # Compiler options for host programs
  #    # https://docs.kernel.org/kbuild/makefiles.html#controlling-compiler-options-for-host-programs
  #    # HOSTCFLAGS, HOSTCXXFLAGS
  #    #
  #    # User supplied flags:
  #    # KCPPFLAGS, KAFLAGS, KCFLAGS and KRUSTFLAGS
  #    #
  #    # eg:
  #    # extraMakeFlags = [
  #    #   "KCFLAGS+=-march=native"
  #    #   "KCFLAGS+=-mtune=native"
  #    # ];
  #  };
  #});

  #linuxPackages_latest = prev.linuxPackages_latest.extend (kfinal: kprev: {
  #  kernel = kprev.kernel.override {
  #    argsOverride = rec {
  #      # see: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/kernels-org.json
  #      version = "6.8.8";
  #      modDirVersion = final.lib.versions.pad 3 version;
  #      src = final.fetchurl {
  #        url = "mirror://kernel/linux/kernel/v${final.lib.versions.major version}/linux-${version}.tar.xz";
  #        sha256 = "sha256:1fiiyvwi6frn83z730w4mng2z4nwpspvhb6vjpxx3yk0snwxqk0w";
  #      };
  #    };

  #    extraMakeFlags = [
  #      "KCFLAGS+=-march=native"
  #      "KCFLAGS+=-mtune=native"
  #      "KCPPFLAGS+=-march=native"
  #      "KCPPFLAGS+=-mtune=native"
  #    ];
  #  };
  #});

  #linuxPackages_latest = prev.linuxPackages_latest.extend (kfinal: kprev: {
  #  opensnitch-ebpf = kprev.opensnitch-ebpf.overrideAttrs
  #    (old: {
  #      env.NIX_CFLAGS_COMPILE = "-fcf-protection -fno-stack-protector";
  #      env.KERNEL_DIR = "${kfinal.kernel.dev}/lib/modules/${kfinal.kernel.modDirVersion}/source";
  #      env.KERNEL_HEADERS = "${kfinal.kernel.dev}/lib/modules/${kfinal.kernel.modDirVersion}/build";

  #      buildPhase = ''
  #        runHook preBuild

  #        make
  #        llvm-strip -g opensnitch{,-dns,-procs}.o

  #        runHook postBuild
  #      '';
  #    });
  #});
}
