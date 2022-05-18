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
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home_manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs_stable";
    };
  };

  outputs = { self, nixpkgs_stable, nixpkgs_unstable, home_manager, ... }@inputs:
    let
      lib = import ./lib {
        inherit pkgs;
        pkgs_i686 = pkgs_i686;
        nix_lib = nixpkgs_stable.lib;
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

      pkgs_unstable = import nixpkgs_unstable {
        system = "x86_64-linux";
        overlays = overrides ++ [ bwrap ];
        config.allowUnfreePredicate = prefs.unfree_packages;
      };
      pkgs = import nixpkgs_stable {
        system = "x86_64-linux";
        overlays = overrides ++ [ bwrap ];
        config.allowUnfreePredicate = prefs.unfree_packages;
        config.android_sdk.accept_license = true;
      };
      pkgs_i686 = import nixpkgs_stable {
        system = "i686-linux";
        overlays = overrides ++ [ bwrap ];
        config.allowUnfreePredicate = prefs.unfree_packages;
      };

      #############
      # FUNCTIONS #
      #############

      makeSystem = { extra_modules, gpu, cpu }:
        assert builtins.isAttrs pkgs;
        assert builtins.isAttrs pkgs_unstable;
        assert builtins.isAttrs prefs;
        assert lib.asserts.assertOneOf "prefs.gpu" gpu [ "amd" "nvidia" "intel" "unknow" ];
        assert lib.asserts.assertOneOf "prefs.cpu" cpu [ "amd" "intel" "unknow" ];

        let
          prefs' = prefs // { gpu = gpu; cpu = cpu; };
        in
        lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit lib pkgs pkgs_unstable; prefs = prefs'; };
          specialArgs.channels = { inherit nixpkgs_stable nixpkgs_unstable; };
          modules = [
            ./system/common/default.nix

            # Home Manager
            # https://rycee.gitlab.io/home-manager/
            home_manager.nixosModules.home-manager
            {
              home-manager.users = {
                shiryel.imports = [ ./home_manager/shiryel.nix ];
                work.imports = [ ./home_manager/work.nix ];
              };
              home-manager.extraSpecialArgs = { inherit prefs lib pkgs pkgs_unstable; };
              # use the pkgs from nixpkgs system
              home-manager.useGlobalPkgs = true;
              # install packages to /etc/profiles instead of $HOME/.nix-profile
              home-manager.useUserPackages = true;
            }
          ] ++ extra_modules;
        };

    in
    {
      nixosConfigurations.desktop = makeSystem {
        gpu = "amd";
        cpu = "amd";
        extra_modules = [ ./system/profile/desktop.nix ];
      };
      nixosConfigurations.notebook = makeSystem {
        gpu = "amd";
        cpu = "amd";
        extra_modules = [ ./system/profile/notebook.nix ];
      };
      # NOTE: use this to make the initial install on a new computer
      nixosConfigurations.generic = makeSystem {
        gpu = "unknow";
        cpu = "unknow";
        extra_modules = [
          ./system/profile/generic.nix
          ./system/profile/hardware_config.nix
        ];
      };

      # -- DEBUG ONLY --
      # Exposes the values to the `nix repl`
      # nix-repl> :lf .#
      # NOTE: This values are not used by the system
      hh = makeSystem {
        gpu = "amd";
        cpu = "amd";
        extra_modules = [ ./system/profile/desktop.nix ];
      };

      h_lib = lib;
      h_pkgs = pkgs;
      h_pkgs_unstable = pkgs_unstable;
      h_home_manager = home_manager;
      h_inputs = inputs;
    };
}
