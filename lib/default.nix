{ lib
, ...
}:

with builtins;
with lib;

# .extend from `makeExtensible`
lib.extend (final: prev:
let
  my_lib = pipe ./. [
    filesystem.listFilesRecursive
    (filter (file: hasSuffix ".nix" file && file != ./default.nix))
    (map (file: import file { lib = final; }))
    (foldr recursiveUpdate { })
  ];
in
assert isAttrs my_lib;
assert isFunction my_lib.snitchRule;
my_lib
)
