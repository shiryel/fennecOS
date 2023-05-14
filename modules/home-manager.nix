{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fenir.homeManager;
in
{
  options.fenir.homeManager = {
    toAllUsers = mkOption {
      type = with types; attrsOf anything;
      default = { };
      description = "attr added for all users";
    };

    toMainUser = mkOption {
      #type = with types; attrsOf (submodule config.home-manager.users."${config.fenir.mainUser}");
      type = with types; attrsOf anything;
      default = { };
      description = "attr added for the main users";
    };
  };

  config = {
    home-manager = {
      users = {
        "${config.fenir.mainUser}" = mkMerge [
          cfg.toMainUser
          cfg.toAllUsers
        ];
      };
      extraSpecialArgs = { inherit lib pkgs; };
      # use the pkgs from nixpkgs system
      useGlobalPkgs = true;
      # install packages to /etc/profiles instead of $HOME/.nix-profile
      useUserPackages = true;
    };
  };
}
