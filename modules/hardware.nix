{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.hardware;
in
{
  options.myNixOS.hardware = {
    gpu = mkOption {
      type = types.str;
      example = "amd";
      default = "unknow";
      description = mdDoc "GPU of host to use correct packages and modules";
    };

    cpu = mkOption {
      type = types.str;
      example = "amd";
      default = "unknow";
      description = mdDoc "CPU of host to use correct packages and modules";
    };
  };

  config = {
    assertions = [
      { assertion = elem cfg.cpu [ "amd" "intel" "unknow" ]; message = "Invalid CPU"; }
      { assertion = elem cfg.gpu [ "amd" "intel" "nvidia" "unknow" ]; message = "Invalid GPU"; }
    ];

    ##########
    # Mounts #
    ##########

    # use `findmnt -l` to see the fileSystems
    services.btrfs.autoScrub.enable = true;
    services.btrfs.autoScrub.interval = "monthly";

    # Use the systemd-boot EFI boot loader.
    # NOTE: some aditional modules are added were they were due
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    #######
    # CPU #
    #######

    # CPU security
    hardware.cpu.amd.updateMicrocode = cfg.cpu == "amd";

    # Load the correct driver right away
    boot.initrd.kernelModules = optionals (cfg.gpu == "amd") [ "amdgpu" ];
    #services.xserver.videoDrivers = optionals (cfg.gpu == "amd") [ "amdgpu" ]; # add "radeon" if old GPU
    services.xserver.videoDrivers = [ "modesetting" ];

    # Some softwares require these paths for hardware acceleration or for using python GPU libs
    systemd.tmpfiles.rules = [
      "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
      "L+ /opt/amdgpu - - - - ${pkgs.libdrm}"
    ];

    #######
    # GPU #
    #######

    # recompiles some software with support to AMD GPU
    # eg: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/tools/system/btop/default.nix#L12
    nixpkgs.config.rocmSupport = cfg.gpu == "amd";

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true; # required by steam
        #setLdLibraryPath = true;

        # https://nixos.org/manual/nixos/unstable/#sec-gpu-accel
        # https://wiki.nixos.org/wiki/Accelerated_Video_Playback
        extraPackages = with pkgs; [
          # DO NOT ADD amdvlk, mesa RADV is faster

          ### Hardware video acceleration ###
          # https://trac.ffmpeg.org/wiki/HWAccelIntro
          # https://trac.ffmpeg.org/wiki/Hardware/VAAPI
          # initially developed by Intel but can be used in combination with other devices
          #intel-media-driver # iHD driver, for modern GPUs
          #intel-vaapi-driver # i965 driver, for older GPUs

          # https://github.com/i-rinat/libvdpau-va-gl
          # VDPAU driver with VA-API/OpenGL backend.
          #libvdpau-va-gl

          ### OpenCL ###
          # https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/amd/default.nix#L39
          rocmPackages.clr
          rocmPackages.clr.icd

          # fixes `WLR_RENDERER=vulkan sway`
          #vulkan-validation-layers
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      glxinfo # glxgears
      vulkan-tools # vulkaninfo
      clinfo

      rocmPackages.rocminfo
      rocmPackages.rocm-smi # ROCm System Management Interface 
    ];

    # Overclock/Fan Control of CPU/GPU
    #programs.corectrl.enable = true;
    #services.dbus.packages = [ pkgs.corectrl ];
    #users.groups.corectrl = { };
    #users.extraGroups.corectrl.members = [ "shiryel" ];
  };
}
