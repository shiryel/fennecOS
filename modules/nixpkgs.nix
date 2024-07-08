{ pkgs, ... }:

{
  ###############
  # Nix Configs #
  ###############

  nixpkgs.hostPlatform = "x86_64-linux";
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
    '';
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-old --delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  system.stateVersion = "24.05";

  ########
  # Docs #
  ########

  documentation = {
    man = {
      enable = true;
      generateCaches = false; # generate the index (needed by tools like apropos)
    };
    dev.enable = true;
    nixos.enable = true;
  };

  environment.systemPackages = with pkgs; [
    man-pages # linux
    man-pages-posix # POSIX
    stdmanpages # GCC C++
    clang-manpages # Clang
  ];
}
