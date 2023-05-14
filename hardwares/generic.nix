###########################################################
# This file configures a generic config, that will relly
# on the _scripts/setup_disk.sh output
#
# Look at desktop.nix for more tips
###########################################################

{ ... }:

with builtins;

{
  networking = {
    hostName = "generic";
  };
}
