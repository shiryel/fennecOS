###########################################################
# This file configures your AMD CPU / GPU
#
# TEST:
# - Verify Vulkan
#   vulkaninfo | grep GPU
#   vulkaninfo | grep DRI
#
# - Verify OpenGL
#   glxinfo | grep OpenGL
#
# - Monitoring your GPU
#   watch -n 0.5 sudo cat /sys/kernel/debug/dri/0/amdgpu_pm_info
#   https://wiki.archlinux.org/title/AMDGPU#Features
#
# - Testing lavapipe (Mesa LLVMPIPE):
#   VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/lvp_icd.x86_64.json vkcube
#
# NOTES:
# - Other packages needs to be using the same version of Vulkan
#   like Steam or vulkaninfo to work properly
#
# DOCS:
# - https://nixos.wiki/wiki/AMD_GPU
# - https://linux-gaming.kwindu.eu/index.php?title=Improving_performance#AMD
# - https://nixos.wiki/wiki/Accelerated_Video_Playback
# - https://wiki.archlinux.org/title/Hardware_video_acceleration#Verification
# - https://en.wikipedia.org/wiki/OpenCL
#
###########################################################

{ prefs, config, lib, pkgs, pkgs_unstable, ... }:

with lib;

{
  # Overclock/Fan Control of CPU/GPU
  #programs.corectrl.enable = true;
  #users.extraGroups.corectrl.members = [ "shiryel" ];

  # CPU security
  hardware.cpu.amd.updateMicrocode = prefs.cpu == "amd";

  # - load the correct driver right away
  boot.initrd.kernelModules = optionals (prefs.gpu == "amd") [ "amdgpu" ];
  services.xserver.videoDrivers = optionals (prefs.gpu == "amd") [ "amdgpu" ]; # add "radeon" if old GPU

  hardware = {
    opengl = {
      extraPackages = with pkgs; [
        # NOTE:
        # Do not add amdvlk, mesa RADV is faster

        ### Hardware video acceleration ###
        # https://trac.ffmpeg.org/wiki/HWAccelIntro

        # https://trac.ffmpeg.org/wiki/Hardware/VAAPI
        # initially developed by Intel but can be used in combination with other devices
        vaapiIntel

        # https://github.com/i-rinat/libvdpau-va-gl
        # VDPAU driver with VA-API/OpenGL backend.
        #libvdpau-va-gl

        ### OpenCL ###
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.vaapiIntel
        #driversi686Linux.libvdpau-va-gl
      ];
    };
  };

  # RADV is faster: https://www.phoronix.com/review/radv-amdvlk-mid22
  # NOTE: DO NOT ADD VK_ICD_FILENAMES by default, but you can add it to a game or app to test:
  # VK_ICD_FILENAMES="/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json:/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json"
  #environment.variables = {
  #  AMD_VULKAN_ICD = "RADV";
  #};

  environment.systemPackages = with pkgs; [
    # DO NOT INSTALL gpu-burn, will try to install cuda and fail
    #
    glxinfo # glxgears
    vulkan-tools # vulkaninfo
    clinfo
    # vulkan-loader
    # vulkan-headers
    # vulkan-extension-layer

    rocm-smi
    rocm-runtime
    rocm-device-libs
    rocminfo
  ];
}
