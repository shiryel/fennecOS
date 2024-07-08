{
  description = "FennecOS modules and default system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
          nixpkgs.overlays = (with self.lib; with builtins; flatten (pipe ./overlays [
            findModules
            (map (o: import o))
          ]));
        })

        # nix / nixpkgs configs
        {
          nix = {
            # fixes nix-index and set <nixpkgs> to current version
            nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
            #registry.nixpkgs.flake = nixpkgs;
          };
          imports = [
            ./global_options.nix
          ] ++ (self.lib.findModules ./modules);
        }
      ];

      nixosConfigurations.default =
        inputs.nixpkgs.lib.nixosSystem {
          system = null; # system will be set modularly
          # do not add lib, args, specialArgs here, they will conflict with nixpkgs.(...) on modules
          lib = self.lib;
          modules = self.nixosModules.fennecos ++ [
            {
              networking = {
                hostName = "generic";
              };
            }
            ./hardware_config.nix
          ];
        };
    };
}
