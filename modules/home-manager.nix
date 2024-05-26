{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myHM;
in
{
  options.myHM = {
    toAllUsers = mkOption {
      type = with types; attrsOf anything;
      default = { };
      description = "attr added for all users";
    };

    toMainUser = mkOption {
      #type = with types; attrsOf (submodule config.home-manager.users."${config.myNixOS.mainUser}");
      type = with types; attrsOf anything;
      default = { };
      description = "attr added for the main users";
    };
  };

  config = {
    home-manager = {
      users = {
        "${config.myNixOS.mainUser}" = mkMerge [
          cfg.toMainUser
          cfg.toAllUsers
        ];
      };
      #extraSpecialArgs = { inherit lib pkgs; };
      # use the pkgs from nixpkgs system
      useGlobalPkgs = true;
      # install packages to /etc/profiles instead of $HOME/.nix-profile
      useUserPackages = true;
    };

    myHM.toAllUsers = {
      home.enableNixpkgsReleaseCheck = true;

      programs = {
        git = {
          enable = true;
          extraConfig = {
            init = {
              defaultBranch = "master";
              pull.rebase = true;
              push.default = "current";
            };
          };
          aliases = {
            commend = "commit --amend --no-edit";
            grog = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
            please = "push --force-with-lease";
            root = "rev-parse --show-toplevel";
            # eg: git logme --since 1.day
            # 1.week | 8.hours
            logme = "!git log --pretty=format:\"* %s\" --author `git config user.email`";
          };
          ignores = [ ];
        };

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    };
  };
}
