{ lib, ... }:

with lib;

{
  options.myNixOS = {
    mainUser = mkOption {
      type = types.str;
      example = "shiryel";
      description = "Main user of the system";
    };
  };
}
