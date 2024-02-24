###########################################################
# This file configures your security, with:
# - firewall
# - opensnitch
# - gnupg
# - hardened linux kernel & config
# - kernel audit
#
# TEST:
# - To see the logs from Kernel Audit:
#   sudo journalctl -u audit
# - To see what paths a program requires:
#   strace -e trace=%file program
#
# DOCS: (references)
# - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/hardened.nix
# - https://dataswamp.org/~solene/2022-01-13-nixos-hardened.html
# - https://www.ctrl.blog/entry/systemd-service-hardening.html
# - https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing
###########################################################

{ pkgs, ... }:

{
  # Kernel (default: LTS)
  #boot.kernelPackages = pkgs.linuxPackages_latest-libre;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxKernel.packages.linux_latest_libre;
  #boot.kernelPackages = pkgs.linuxPackages_hardened;
  #boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  #boot.kernelPackages = pkgs.linuxPackages_zen;

  security = {
    # required by podman to run containers in rootless mode when using linuxPackages_hardened
    unprivilegedUsernsClone = true;

    # prevent replacing the running kernel image
    protectKernelImage = true;

    # packages and services can dynamically load kernel modules
    lockKernelModules = false;

    # to build packages from source
    allowUserNamespaces = true;

    # Kernel Audit
    # * DOCS: 
    #   - https://wiki.archlinux.org/title/Audit_framework
    #   - auditctl -h
    #audit = {
    #  enable = false;
    #  rules = [
    #    "-w /home/shiryel/keep/games -p rwxa"
    #  ];
    #};

    # RealtimeKit is optional but recommended
    # Hands out realtime scheduling priority to user processes on demand
    rtkit.enable = true;
  };

  boot.blacklistedKernelModules = [
    # - Obscure network protocols
    "ax25"
    "netrom"
    "rose"

    # - Old or rare or insufficiently audited filesystems
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    "erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs"
  ];

  #######
  # TPM #
  #######
  #
  # Trusted Platform Module (TPM) is an international standard for a secure cryptoprocessor, 
  # which is a dedicated microprocessor designed to secure hardware by integrating 
  # cryptographic keys into devices. 
  # - https://security.stackexchange.com/questions/187820/do-a-tpms-benefits-outweigh-the-risks
  #   Another criticism is that it may be used to prove to remote websites that you are running the software they want you to run, or that you are using a device which is not fully under your control. The TPM can prove to the remote server that your system's firmware has not been tampered with, and if your system's firmware is designed to restrict your rights, then the TPM is proving that your rights are sufficiently curtailed and that you are allowed to watch that latest DRM-ridden video you wanted to see. Thankfully, TPMs are not currently being used to do this, but the technology is there.
  #   TPMs make me nervous because a hardware failure could render me unable to access my own keys and data. That seems more likely than a black hat hacker pulling off a root kit on my OS." - https://youtu.be/RW2zHvVO09g
  #
  # More discussions at: https://news.ycombinator.com/item?id=38149441
  security.tpm2 = {
    enable = false;
    # - userspace resource manager daemon
    abrmd.enable = false;
  };

  ##################################
  # Memory Allocator (not working) #
  ##################################
  #
  # discord "sys_waitpid() for gzip process failed."
  #environment.memoryAllocator.provider = "jemalloc";
  # nixos-rebuild throw "Out of memory"
  #environment.memoryAllocator.provider = "graphene-hardened";
  # firefox not opening
  #environment.memoryAllocator.provider = "scudo";
  #environment.variables.SCUDO_OPTIONS = "ZeroContents=1"; # zero chunk contents on allocation.
}
