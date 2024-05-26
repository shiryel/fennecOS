#
# Functions to optimize a package
#
# From: 
# - https://discourse.nixos.org/t/how-to-recompile-a-package-with-flags/3603/7
# Optimizations: 
# - https://wiki.gentoo.org/wiki/GCC_optimization

pkgs:

rec {
  optimizeWithFlags = pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = [ (old.NIX_CFLAGS_COMPILE or "") ] ++ flags;
    });

  #
  # TAGS:
  #
  # pipe - makes the compilation process faster. It tells the compiler to use pipes instead of temporary files during the different stages of compilation, which uses more memory. On systems with low memory, GCC might get killed. In those cases do not use this flag. 
  # -fpic -shared - no text relocations for shared libraries; Address Space Layout Randomization (ASLR) is a state-of-the-art measure to increase security by randomly placing each function and buffer in memory. This makes it harder for attack vectors to succeed.

  optimizeForThisHost = pkg:
    optimizeWithFlags pkg [ "-O3" "-march=native" "-mtune=native" "-fPIC" "-pipe" ];

  withDebuggingCompiled = pkg:
    optimizeWithFlags pkg [ "-DDEBUG" ];
}
