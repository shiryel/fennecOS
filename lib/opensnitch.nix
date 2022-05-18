{ lib, pkgs, ... }:

with builtins;
with lib;

{
  snitchRule = (action: name: data:
    let
      txt = pkgs.writeText "allow-${name}.json" ''
        {
          "created": "2022-10-07T21:55:00.000000000-03:00",
          "updated": "2022-10-07T21:55:00.000000000-03:00",
          "name": "allow-${name}",
          "enabled": true,
          "precedence": false,
          "action": "${action}",
          "duration": "always",
          "operator": {
            "type": "simple",
            "operand": "process.path",
            "sensitive": false,
            "data": "${data}",
            "list": []
          }
        }
      '';
    in
    "L /var/lib/opensnitch/rules/${action}-${name}.json - - - - ${txt}"
  );

  # options:
  # - path: string
  snitchAllowPath = (path:
    let
      name = pipe path [
        (strings.removePrefix "/nix/store/")
        (strings.splitString "/")
        lists.reverseList
        lists.last
      ];
    in
    snitchRule "allow" name path
  );

  # options:
  # - path: string
  snitchDenyPath = (path:
    let
      name = pipe path [
        (strings.removePrefix "/nix/store/")
        (strings.splitString "/")
        lists.reverseList
        lists.last
      ];
    in
    snitchRule "deny" name path
  );

  # options:
  # - ip: string
  #
  # NOTE: it has priority (precedence) than other rules
  snitchAllowIp = (ip:
    let
      txt = pkgs.writeText "allow-ip-${ip}.json" ''
        {
          "created": "2022-10-07T21:55:00.000000000-03:00",
          "updated": "2022-10-07T21:55:00.000000000-03:00",
          "name": "allow-ip-${ip}",
          "enabled": true,
          "precedence": true,
          "action": "allow",
          "duration": "always",
          "operator": {
            "type": "simple",
            "operand": "dest.ip",
            "sensitive": false,
            "data": "${ip}",
            "list": []
          }
        }
      '';
    in
    "L /var/lib/opensnitch/rules/allow-ip-${ip}.json - - - - ${txt}"
  );
}

