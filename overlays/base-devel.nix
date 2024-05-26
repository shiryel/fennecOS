final: prev: {
  # Archlinux base-devel packages
  # https://archlinuxarm.org/packages/any/base-devel
  arch-base-devel = prev.symlinkJoin {
    name = "arch-base-devel";
    paths = with final; [
      autoconf
      automake
      binutils
      bison
      debugedit
      fakeroot
      file
      findutils
      flex
      gawk
      gcc
      gettext
      gnugrep
      groff
      gzip
      libtool
      m4
      gnumake
      patch
      gnused
      which
    ];
  };
}
