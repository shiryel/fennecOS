{ lib, pkgs, pkgs_i686, ... }:

with builtins;
with lib;

# NOTE:
# A fake dbus like this Will hide tray and fix some issues, 
# but some apps will keep running in backgroud
#
# fake_dbus =
#   if fake_dbus then "export $(dbus-launch)" else "";

{
  _bwrap_args = (
    { name
    , package ? null
    , args ? ''"$@"''
    , exec ? "bin/${name}"
    , binds ? [ ] # [string] | [{from: string; to: string;}]
    , ro_binds ? [ ] # [string] | [{from: string; to: string;}]
    , unshare ? "--unshare-all"
    , default_binds ? true
    , dri ? false # video acceleration
    , dev ? false # Vulkan support / devices usage
    , xdg ? false
    , net ? false
    , tmp ? false # some tray icons needs it
    , ld_cache ? false
    , custom_config ? [ ]
      # Fixes "cannot set terminal process group (-1)" but is 
      # not recommended because of a security issue with TIOCSTI [1]
      # [1] - https://wiki.archlinux.org/title/Bubblewrap#New_session
    , keep_session ? false
    }:
    assert isString args;
    assert isString exec;
    assert isList binds;
    assert isList ro_binds;
    assert isString unshare;
    assert isBool default_binds;
    assert isBool dri;
    assert isBool dev;
    assert isBool xdg;
    assert isBool net;
    assert isBool tmp;
    assert isBool ld_cache;
    assert isList custom_config;
    assert isBool keep_session;
    let
      # Normalizes to [{from: string; to: string;}]
      _normalize_binds = map
        (x:
          if x ? from && x ? to
          then x
          else { from = x; to = x; });

      # Bwrap can't bind symlinks correctly, it needs canonicalized paths [1]
      # `readlink -m` solves this issue
      # [1] - https://github.com/containers/bubblewrap/issues/195
      _rw_binds = pipe binds [
        _normalize_binds
        # Sometimes a program will call itself, and their home will be "new" without the
        # files that it was working with (or without the file of others programs that uses
        # the same bwrap enviroment, like steam, steam-run and protontricks). To fix this
        # problem we bind the bwrap enviroment inside itself, so it will be available in case
        # the program call itself (and create a new bwrap)
        (b: b ++ (map (x: if isList (match ".*(bwrap).*" x.from) then [{ from = x.from; to = x.from; }] else [ ]) b))
        lists.flatten
        (map (x: ''--bind-try $(readlink -mn ${x.from}) ${x.to}''))
        (concatStringsSep " \\\n")
      ];

      _default_ro_binds =
        if default_binds then [
          "~/.config/dconf"
          "~/.config/gtk-3.0/settings.ini"
          "~/.config/gtk-4.0/settings.ini"
          "~/.gtkrc-2.0"
        ] else [ ];

      _ro_binds = pipe (ro_binds ++ _default_ro_binds) [
        _normalize_binds
        (map (x: ''--ro-bind-try $(readlink -mn ${x.from}) ${x.to}''))
        (concatStringsSep " \\\n")
      ];

      # mkdir -p (only if bwrap is on the name)
      _mkdir = pipe binds [
        _normalize_binds
        (map (x: if isList (match ".*(bwrap).*" x.from) then "mkdir -p ${x.from}" else ""))
        (concatStringsSep "\n")
      ];

      _dev_or_dri =
        if dri || dev then
          (if dev then
            "--dev-bind /dev /dev"
          else
            "--dev /dev --dev-bind /dev/dri /dev/dri")
        else "--dev /dev";

      # Our glibc will look for the cache in its own path in `/nix/store`.
      # As such, we need a cache to exist there, because pressure-vessel
      # depends on the existence of an ld cache.
      # Also, the cache needs to go to both 32 and 64 bit glibcs, for games
      # of both architectures to work.
      _ld_cache =
        if ld_cache then
          ''
            --tmpfs ${pkgs.glibc}/etc
            --symlink /etc/ld.so.conf ${pkgs.glibc}/etc/ld.so.conf
            --symlink /etc/ld.so.cache ${pkgs.glibc}/etc/ld.so.cache
            --ro-bind ${pkgs.glibc}/etc/rpc ${pkgs.glibc}/etc/rpc
            --remount-ro ${pkgs.glibc}/etc
            --tmpfs ${pkgs_i686.glibc}/etc
            --symlink /etc/ld.so.conf ${pkgs_i686.glibc}/etc/ld.so.conf
            --symlink /etc/ld.so.cache ${pkgs_i686.glibc}/etc/ld.so.cache
            --ro-bind ${pkgs_i686.glibc}/etc/rpc ${pkgs_i686.glibc}/etc/rpc
            --remount-ro ${pkgs_i686.glibc}/etc
          ''
        else
          "";

      # read-only by default (--ro-bind /run /run)
      _xdg = if xdg then "--bind $XDG_RUNTIME_DIR $XDG_RUNTIME_DIR" else "";

      _net = if net then "--share-net" else "";
      _tmp = if tmp then "--bind /tmp /tmp" else "--tmpfs /tmp";
      _new_session = if keep_session then "" else "--new-session";
      _custom_config = concatStringsSep " " custom_config;
    in
    {
      name = name;
      package = package;
      args = args;
      exec = exec;
      rw_binds = _rw_binds;
      ro_binds = _ro_binds;
      mkdir = _mkdir;
      unshare = unshare;
      dev_or_dri = _dev_or_dri;
      xdg = _xdg;
      net = _net;
      tmp = _tmp;
      ld_cache = _ld_cache;
      custom_config = _custom_config;
      new_session = _new_session;
    }
  );

  bwrapIt = (bwrap_args:
    let
      _result = override_args:
        with (_bwrap_args bwrap_args);

        assert package != null;

        # bind /bin for using xdg-open (eg: telegram) and 
        # to fix sh and bash for some scripts
        #
        # NOTE: Remember to follow the binding order from ~/
        # eg: ~/ ~/.config ~/.config/*
        pkgs.writeScriptBin name ''
          #!${pkgs.stdenv.shell}
          ${mkdir}
          cmd=(
            ${lib.getBin pkgs.bubblewrap}/bin/bwrap
            --ro-bind /run /run
            --ro-bind /bin/sh /bin/sh
            --ro-bind /bin/sh /bin/bash
            --ro-bind /etc /etc
            --ro-bind /nix /nix
            --ro-bind /sys /sys
            --ro-bind /var /var
            --ro-bind /usr /usr
            --proc /proc
            --tmpfs /home
            --die-with-parent
            ${ld_cache}
            ${new_session}
            ${unshare}
            ${dev_or_dri}
            ${xdg}
            ${net}
            ${tmp}
            ${rw_binds}
            ${ro_binds}
            ${custom_config}
            # only tries to override when necessary, otherwise it
            # would fail with packages that can't override
            ${lib.getBin (
              if (override_args == {})
              then package
              else (package.override override_args)
            )}/${exec} ${args}
            )
          exec -a "$0" "''${cmd[@]}"
        '';
    in
    makeOverridable _result { }
  );

  fhsIt = (
    bwrap_args: targetPkgs:
      (with (_bwrap_args bwrap_args);

      assert package == null;

      pkgs.writeScriptBin name ''
        #! ${pkgs.stdenv.shell} -e
        ${mkdir}

        ${pkgs.buildFHSUserEnvBubblewrap {
          name = "${name}";
          runScript = "${exec} ${args}";
          targetPkgs = targetPkgs;
          extraBwrapArgs = [
            "--proc /proc"
            "--tmpfs /home"
            "--die-with-parent"
            "${ld_cache}"
            "${new_session}"
            "${unshare}"
            "${dev_or_dri}"
            "${xdg}"
            "${net}"
            "${tmp}"
            "${rw_binds}"
            "${ro_binds}"
            "${custom_config}"
          ];
        }}/bin/${name}
      ''
      )
  );
}
