{ lib, ... }:

with builtins;
with lib;

{
  snitchRule = (
    { action
    , name
    , type ? "simple"
    , operand ? "process.path"
    , data
    , list ? [ ]
    , precedence ? false
    }:
      assert isString action;
      assert isString name;
      assert isString type;
      assert isString operand;
      assert isString data;
      assert isList list;
      assert isBool precedence;
      {
        created = "2022-10-07T21:55:00.000000000-03:00";
        updated = "2022-10-07T21:55:00.000000000-03:00";
        name = "${action}-${name}";
        enabled = true;
        precedence = precedence;
        action = action;
        duration = "always";
        operator = {
          type = type;
          operand = operand;
          sensitive = false;
          data = data;
          list = list;
        };
      }
  );

  snitchAllowPath = (path:
    assert isString path;
    snitchRule { action = "allow"; name = getNameFromPath path; data = path; }
  );

  snitchDenyPath = (path:
    assert isString path;
    snitchRule { action = "deny"; name = getNameFromPath path; data = path; }
  );

  # NOTE: it has priority (precedence) than other rules
  snitchAllowIp = (ip:
    assert isString ip;
    snitchRule { action = "allow"; name = "ip-${ip}"; operand = "dest.ip"; data = ip; precedence = true; }
  );

  snitchAllowHost = (host:
    assert isString host;
    snitchRule { action = "allow"; name = "host-${host}"; operand = "dest.host"; data = host; }
  );

  # eg: 
  # lib.snitchAllowNetwork "::1/128";
  # lib.snitchAllowNetwork "127.0.0.0/8";
  snitchAllowNetwork = (network:
    assert isString network;
    snitchRule { action = "allow"; name = "network-${ip}"; operand = "dest.network"; data = network; }
  );

  getNameFromPath = (path:
    pipe path [
      (strings.removePrefix "/nix/store/")
      (strings.splitString "/")
      lists.reverseList
      lists.last
    ]
  );
}

