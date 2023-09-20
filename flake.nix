{
  description = "FennecOS modules and default system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home_manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extendedLib = import ./lib {
        inherit pkgs;
        lib = nixpkgs.lib;
      };
    in
    {
      lib = extendedLib;

      nixosModules.fennecos = [
        #./configuration.nix
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.overlays = with self.lib; with builtins; flatten (pipe ./overlays [
            findModules
            attrValues
            (map (o: import o))
          ]);
          nix = {
            # fixes nix-index and set <nixpkgs> to current version
            nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
            #registry.nixpkgs.flake = nixpkgs;
          };
        }
        ./modules
        inputs.home_manager.nixosModules.home-manager
      ];

      nixosConfigurations.default =
        nixpkgs.lib.nixosSystem {
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
