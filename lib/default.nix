{ pkgs
, pkgs_i686
, nix_lib
, hm_lib
, ...
}:

with builtins;
with nix_lib;

assert isAttrs nix_lib;
assert isAttrs hm_lib;

# .extend from `makeExtensible`
nix_lib.extend (final: prev:
let
  my_lib = pipe ./. [
    filesystem.listFilesRecursive
    (filter (file: hasSuffix ".nix" file && file != ./default.nix))
    (map (file: import file { inherit pkgs; inherit pkgs_i686; lib = final; }))
    (foldr recursiveUpdate { })
  ];
in
assert isAttrs my_lib;
{ hm = hm_lib.hm; } // my_lib
)
