{ ... }:

{
  imports =
    [
      ./network.nix
      ./kernel.nix
      ./systemd.nix
      ./services.nix
    ];
}
