{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.livebook;

  rocmPkgs = with pkgs; [
    # maybe not necessary
    rocmPackages.rocm-cmake
    rocmPackages.rocm-comgr
    rocmPackages.rocm-device-libs
    rocmPackages.rocm-smi
    rocmPackages.rocm-thunk
    rocmPackages.rocmlir
    rocmPackages.rocmlir-rock

    #llvmPackages_rocm.clang
    llvmPackages_rocm.clang-unwrapped.out
    hip-amd

    # absolutelly necessary:
    rocmPackages.rocm-core
    rocmPackages.rocm-runtime # hsa-runtime64
    rocmPackages.clr # hip
    miopen
    rocblas
    rocrand
    rocfft
    hipfft
    roctracer
    hipsparse
    hipsolver
    rocsolver
    rccl
    hipblas
  ];

  rocmFull = pkgs.symlinkJoin {
    name = "rocm-full";
    paths = rocmPkgs;
  };
in
{
  options.myNixOS.livebook.enable = mkEnableOption (mdDoc "enables livebook systemd service");

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules =
      [
        "L+    /opt/rocm    -    -    -     -    ${rocmFull}"
        # fixes 'src/main/tools/process-wrapper-legacy.cc:80: "execvp(/usr/bin/ar, ...)": No such file or directory"
        "L+    /usr/bin/ar -    -    -     -    ${pkgs.binutils}/bin/ar"
        #"L+    /opt/rocm/include/rocblas.h -    -    -     -    ${pkgs.rocblas}/include/rocblas/rocblas.h"
      ];

    systemd.user.services.livebook =
      let
        baseDir = "/home/${config.myNixOS.mainUser}/livebook";
      in
      {
        description = "Automate code & data workflows with interactive Elixir notebooks";
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];

        path = with pkgs; [
          bash # for erlang's disksup to work
          coreutils # mkdir/chown/chmod for ExecStart
          busybox # which
          binutils # ar

          # for AXON build Rocm
          elixir
          bazel_6
          #python3
          (python3.withPackages (ps: with ps; [ numpy ]))
          #.env
          #python3Packages.numpy
          git
          gcc # between gcc7 or gcc9
          gnumake

          # maybe not
          #rocm-cmake
        ] ++ rocmPkgs;

        environment = {
          LIVEBOOK_TOKEN_ENABLED = "false";
          LIVEBOOK_PORT = "7100";
          #CC = pkgs.gcc;
          #LIVEBOOK_DATA_PATH = "${baseDir}";
          #LIVEBOOK_HOME = baseDir;
          #ROCM_PATH = pkgs.rocm-core;

          # for tensorflow
          #TENSORFLOW_GIT_REPO = "https://github.com/ROCmSoftwarePlatform/tensorflow-upstream.git";
          #TENSORFLOW_GIT_REV = "edca0e1548d4b57baa55bcc2d62ed2bc0d64a650";

          # for openxla
          #OPENXLA_GIT_REV = "660d3fd359083d67c072d879358c33bdfc85bee9";

          #TF_NEED_ROCM = "1";
          #XLA_BUILD = "true";
          #XLA_TARGET = "rocm";
          # not necessary:
          #TF_ROCM_FUSION_ENABLE = "1";
        };

        unitConfig = {
          ConditionUser = config.myNixOS.mainUser;
          StartLimitInterval = "60s";
        };

        # https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing
        serviceConfig = {
          ExecStart = "${pkgs.livebook}/bin/livebook server";
          #ExecStartPre = [
          #  "${pkgs.elixir}/bin/mix local.rebar --force"
          #  "${pkgs.elixir}/bin/mix local.hex --force"
          #];
          #BindPaths = baseDir;
          #ProtectHome = "tmpfs"; # required by BindPaths
          #PrivateUsers = true; # required by ProtectHome

          #NoNewPrivileges = true;
          #LockPersonality = true;
          #InaccessiblePaths = ["-/keep" "-/run"];
          ##MemoryDenyWriteExecute = true;
          ##NoNewPrivileges = true;
          #ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
          #PrivateTmp = true;
          ##PrivateDevices = true;
          #PrivateMounts = true;
        };
      };
  };
}
