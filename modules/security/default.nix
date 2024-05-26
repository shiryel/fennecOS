{ pkgs, ... }:

{
  imports =
    [
      ./network.nix
      ./kernel.nix
      ./systemd.nix
      ./services.nix
    ];

  # Mitigates https://github.com/NixOS/nixpkgs/issues/300055
  # --impure flag is required
  #system.replaceRuntimeDependencies = [
  #  {
  #    original = pkgs.xz;
  #    replacement = pkgs.nixpkgs-stable.xz;
  #  }
  #];
}
