{
  description = "FennecOS modules and default system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-staging-next.url = "github:NixOS/nixpkgs/staging-next";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    #home_manager = {
    #  url = "github:nix-community/home-manager/master";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs = { self, ... }@inputs:
    {
      # extends lib and make it available on self.lib to be imported from other flakes
      lib = import ./lib {
        lib = inputs.nixpkgs.lib;
      };

      # this is the module that will be used on your nixosConfigurations
      # see nixosConfigurations.default bellow as an example
      nixosModules.fennecos = [
        # overlays
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            (f: p: {
              nixpkgs-staging-next = inputs.nixpkgs-staging-next.legacyPackages.${pkgs.system};
              nixpkgs-stable = inputs.nixpkgs-stable.legacyPackages.${pkgs.system};
            })
          ] ++ (with self.lib; with builtins; flatten (pipe ./overlays [
            findModules
            attrValues
            (map (o: import o))
          ]));
        })

        # nix / nixpkgs configs
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nix = {
            # fixes nix-index and set <nixpkgs> to current version
            nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
            #registry.nixpkgs.flake = nixpkgs;
          };
        }
        ./modules
        #inputs.home_manager.nixosModules.home-manager
      ];

      nixosConfigurations.default =
        inputs.nixpkgs.lib.nixosSystem {
          system = null; # system will be set modularly
          # do not add lib, args, specialArgs here, they will conflict with nixpkgs.(...) on modules
          lib = self.lib;
          modules = self.nixosModules.fennecos ++ [
            {
              myNixOS.stateVersion = "23.11";
              networking = {
                hostName = "generic";
              };
            }
            ./hardware_config.nix
          ];
        };
    };
}
