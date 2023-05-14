# This file is where the magic starts
#
# Here we define a flake that holds many `nixosConfigurations`
# Those configurations can be run like:
# sudo nixos-rebuild switch --flake '.#shiryel'
#
# Also here is were we declare and mix things, like new functions on the `lib`
# and custom overlays

###########################################
# Some extra places that you can get help #
#
# NixOS manual - https://nixos.org/manual/nixos/stable/
# Nixpkgs manual - https://nixos.org/manual/nixpkgs/stable/
# Nix lang manual - https://nixos.org/manual/nix/stable/
# How to package - https://nixos.wiki/wiki/Packaging/Tutorial

####################################
# How to build from CUSTOM nixpkgs #
# To build manually:
# > nix develop --ignore-environment .#blender
# > unpackPhase
# > patchPhase
# > buildPhase
#
# To install and test:
# > export NIXPKGS=~/projects/nixpkgs
# > nix-env -f $NIXPKGS -iA blender
# > nix-shell -f $NIXPKGS -p python39Packages.gdtoolkit

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    home_manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs_stable, home_manager, ... }@inputs:
    let
      lib = import ./lib {
        inherit pkgs;
        pkgs_i686 = pkgs_i686;
        nix_lib = nixpkgs.lib;
        hm_lib = home_manager.lib;
      };

      prefs = import ./prefs.nix { inherit lib; };

      overrides = lib.pipe ./overlays/overrides [
        lib.findModules
        builtins.attrValues
        (map (o: import o { inherit lib prefs; }))
      ];

      bwrap = import ./overlays/bwrap.nix {
        inherit lib prefs;
      };

      ############
      # PACKAGES #
      ############

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = overrides ++ [ bwrap ];
        config.allowUnfreePredicate = prefs.unfree_packages;
        config.android_sdk.accept_license = true;
      };
      pkgs_stable = import nixpkgs_stable {
        system = "x86_64-linux";
        overlays = overrides ++ [ bwrap ];
        config.allowUnfreePredicate = prefs.unfree_packages;
      };
      pkgs_i686 = import nixpkgs {
        system = "i686-linux";
        overlays = overrides ++ [ bwrap ];
        config.allowUnfreePredicate = prefs.unfree_packages;
      };

      #############
      # FUNCTIONS #
      #############

      makeSystem = { extra_modules }:
        assert builtins.isAttrs pkgs;
        assert builtins.isAttrs pkgs_stable;
        assert builtins.isAttrs prefs;
        #assert lib.asserts.assertOneOf "prefs.gpu" gpu [ "amd" "nvidia" "intel" "unknow" ];
        #assert lib.asserts.assertOneOf "prefs.cpu" cpu [ "amd" "intel" "unknow" ];

        lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit lib pkgs pkgs_stable; };
          modules = [
            ./profiles/shiryel.nix
            ./modules
            home_manager.nixosModules.home-manager
          ] ++ extra_modules;
        };
    in
    {
      nixosConfigurations.desktop = makeSystem {
        extra_modules = [ ./hardwares/desktop.nix ];
      };
      nixosConfigurations.notebook = makeSystem {
        extra_modules = [ ./hardwares/notebook.nix ];
      };
      # NOTE: use this to make the initial install on a new computer
      nixosConfigurations.generic = makeSystem {
        extra_modules = [
          ./hardwares/generic.nix
          ./hardware_config.nix
        ];
      };

      # -- DEBUG ONLY --
      # Exposes the values to the `nix repl`
      # nix-repl> :lf .#
      # NOTE: This values are not used by the system
      h_lib = lib;
      h_pkgs = pkgs;
      h_home_manager = home_manager;
      h_inputs = inputs;
    };
}
