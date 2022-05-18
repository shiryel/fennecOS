{ lib, prefs, ... }:

with lib;

final: prev:
let
  common_binds = prefs.bwrap_binds.common;
  data_binds = prefs.bwrap_binds.docs;
  code_binds = prefs.bwrap_binds.common;
  game_binds = prefs.bwrap_binds.game;

  no_wayland_support_fix = [
    # Fix games breaking on wayland
    "--unsetenv XDG_SESSION_TYPE"
    "--unsetenv CLUTTER_BACKEND"
    "--unsetenv QT_QPA_PLATFORM"
    "--unsetenv SDL_VIDEODRIVER"
    "--unsetenv SDL_AUDIODRIVER"
    "--unsetenv NIXOS_OZONE_WL"
  ];

  steam_common = {
    dev = true; # required for vulkan
    net = true;
    tmp = true;
    xdg = prefs.steam.vr_integration;
    binds =
      [
        # you can run a proton game with the TARGET: explorer.exe
        # to verify if the proton is not accessing the wrong files
        {
          from = "~/bwrap/steam";
          to = "~/";
        }
        "~/.config/MangoHud/MangoHud.conf"
      ] ++ prefs.bwrap_binds.game;
    custom_config = no_wayland_support_fix ++ [
      # Proton-GE
      "--setenv STEAM_EXTRA_COMPAT_TOOLS_PATHS ${
            prev.stdenv.mkDerivation rec {
              pname = "proton-ge-custom";
              version = "GE-Proton7-53";

              src = prev.fetchurl {
                url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
                sha256 = "sha256-J3e/WM/Cms8uqCOcjIQjFQZJL++rrIenhnpLsCbwwXA=";
              };

              buildCommand = ''
                mkdir -p $out
                tar -C $out --strip=1 -x -f $src
              '';
            }
          }"
    ] ++ optionals prefs.steam.vr_integration [
      "--setenv VR_OVERRIDE ${prev.open-composite}"
      "--setenv XR_RUNTIME_JSON ${prev.monado}/share/openxr/1/openxr_monado.json"
      "--setenv PRESSURE_VESSEL_FILESYSTEMS_RW $XDG_RUNTIME_DIR/monado_comp_ipc"
    ];
  };
in
{
  _no_bwrap = prev;

  ##############
  # WORKSPACES #
  ##############
  # NOTES:
  # - FHS by default mounts every root directory, with the exception
  #   of /nix /dev /proc /etc (so expect XDG to work)
  # - Podman will not work as /etc/subuid does not exists 
  #   (maybe fix with rootless mode?)

  shiryel-workspace =

    (lib.fhsIt
      {
        name = "shiryel-workspace";
        exec = "kitty";
        dev = true;
        net = true;
        binds = [
          {
            from = "~/bwrap/_workspaces/shiryel";
            to = "~/";
          }
        ];
        ro_binds = [
          "~/.config/kitty/kitty.conf"
          "~/.zshrc"
          "~/.zshenv"
          "~/.zlogin"
          "~/.zprofile"
        ];
      }
      (pkgs: with pkgs; [
        kitty
        #flutter
        #android-studio-canary
      ])
    );

  work-workspace = (lib.fhsIt
    {
      name = "work-workspace";
      exec = "kitty";
      dri = true;
      net = true;
      binds = [
        {
          from = "~/bwrap/_workspaces/work";
          to = "~/";
        }
      ];
      ro_binds = [
        "~/.config/kitty/kitty.conf"
        "~/.zshrc"
        "~/.zshenv"
        "~/.zlogin"
        "~/.zprofile"
      ];
    }
    (pkgs: with pkgs; [
      kitty
      #flutter
      #android-studio-canary
    ])
  );

  #########
  # GAMES #
  #########

  steam =
    (lib.bwrapIt
      ({
        name = "steam";
        package = prev.steam;
        args = ''-console -nochatui -nofriendsui -silent "$@"'';
      } // steam_common));

  steam-run =
    (lib.bwrapIt
      ({
        name = "steam-run";
        package = prev.steam.run;
      } // steam_common));

  protontricks =
    (lib.bwrapIt
      ({
        name = "protontricks";
        package = prev.protontricks;
      } // steam_common));

  monado =
    (lib.bwrapIt {
      name = "steam-vr";
      package = prev.monado;
      exec = "bin/monado-service";
      args = "$@";
      dev = true; # required for vulkan
      tmp = true;
      xdg = true;
      binds = [ ];
    });

  # https://www.reddit.com/r/linux_gaming/comments/99e0kc/steam_playguide_create_custom_32bit_prefix_to/
  # WINEARCH=win32 winecfg
  # wine explorer /desktop=name,1024x868 program.exe
  wine_fhs =
    (lib.fhsIt
      {
        name = "wine_fhs";
        exec = "zsh";
        #dri = true;
        tmp = true;
        net = true;
        # testing...
        dev = true;
        xdg = true;
        keep_session = true;
        binds = [
          {
            from = "~/bwrap/wine";
            to = "~/";
          }
        ] ++ game_binds;
      }
      (pkgs: with pkgs; [
        prev.wineWowPackages.waylandFull
        #pkgs.wineWowPackages.full
        pkgs.winetricks
      ]));

  lutris =
    (lib.bwrapIt {
      name = "lutris";
      package = prev.lutris;
      dri = true; # required for vulkan
      net = true;
      xdg = true;
      ld_cache = true;
      binds = [
        {
          from = "~/bwrap/lutris";
          to = "~/";
        }
      ] ++ game_binds;
      custom_config = no_wayland_support_fix;
    });

  yuzu =
    (lib.bwrapIt {
      name = "yuzu";
      package = prev.yuzu-early-access;
      net = true;
      dev = true; # for controllers
      binds = [
        {
          from = "~/bwrap/yuzu";
          to = "~/";
        }
        "/keep/games"
      ];
    });


  ############
  # BROWSERS #
  ############

  # FIXME: ALSA lib seq_hw.c:466:(snd_seq_hw_open) open /dev/snd/seq failed: No such file or directory
  firefox =
    (lib.bwrapIt {
      name = "firefox";
      package = prev.firefox;
      net = true;
      dri = true;
      xdg = true;
      default_binds = false;
      binds = [
        {
          from = "~/bwrap/mozilla";
          to = "~/.mozilla";
        }
        #"$XDG_RUNTIME_DIR/dconf/"
      ] ++ common_binds ++ data_binds;
      custom_config = [
        #"--setenv MOZ_ENABLE_WAYLAND 1"
        #"--setenv MOZ_USE_XINPUT2 1"
      ];
    });

  librewolf =
    (lib.bwrapIt {
      name = "librewolf";
      package = prev.librewolf;
      net = true;
      dri = true;
      xdg = true;
      binds = [
        {
          from = "~/bwrap/librewolf";
          to = "~/.librewolf";
        }
      ] ++ common_binds;
    });

  tor-browser =
    (lib.bwrapIt {
      name = "tor-browser";
      package = prev.tor-browser-bundle-bin;
      net = true;
      binds = [
        {
          from = "~/bwrap/tor-browser";
          to = "~/";
        }
      ];
    });

  ungoogled-chromium =
    (lib.bwrapIt {
      name = "ungoogled-chromium";
      package = prev.ungoogled-chromium;
      net = true;
      dev = true; # webcam support
      binds = [
        {
          from = "~/bwrap/chromium";
          to = "~/";
        }
      ] ++ common_binds ++ data_binds;
    });

  chromium =
    (lib.bwrapIt {
      name = "chromium";
      package = prev.chromium;
      net = true;
      dev = true; # webcam support
      binds = [
        {
          from = "~/bwrap/chromium";
          to = "~/";
        }
      ] ++ common_binds ++ data_binds;
    });

  ########
  # CHAT #
  ########

  tdesktop =
    (lib.bwrapIt {
      name = "telegram-desktop";
      package = prev.tdesktop;
      net = true;
      dri = true;
      #xdg = true; # fixes gtk file picker
      binds = [
        {
          from = "~/bwrap/telegram";
          to = "~/";
        }
      ] ++ common_binds ++ data_binds;
      custom_config = [
        #"--setenv XDG_CURRENT_DESKTOP sway:gnome" # makes gtk file picker work
      ];
    });

  #signal-desktop =
  #  (lib.bwrapIt {
  #    name = "signal-desktop";
  #    package = prev.signal-desktop;
  #    net = true;
  #    binds = [
  #      {
  #        from = "~/bwrap/signal";
  #        to = "~/";
  #      }
  #    ] ++ common_binds;
  #  });

  thunderbird =
    (lib.bwrapIt {
      name = "thunderbird";
      args = "-no-remote";
      package = prev.thunderbird;
      net = true;
      xdg = true;
      binds = [
        {
          from = "~/bwrap/thunderbird";
          to = "~/";
        }
      ] ++ common_binds;
    });

  #########
  # TOOLS #
  #########

  neovim = (lib.bwrapIt {
    name = "nvim";
    net = true;
    tmp = true;
    binds = [
      {
        from = "~/bwrap/nvim";
        to = "~/";
      }
      "~/exercism"
      "~/projects"
      "~/logs"
      "~/.mix"
    ];
    # neovim is already wrapped on the pkgs/top-level/all-packages.nix from nixpkgs
    package = prev.neovim;
  });

  insomnia =
    (lib.bwrapIt {
      name = "insomnia";
      package = prev.insomnia;
      net = true;
      dri = true;
      binds = [
        {
          from = "~/bwrap/insomnia";
          to = "~/";
        }
      ];
    });

  phoronix-test-suite =
    (lib.bwrapIt {
      name = "phoronix-test-suite";
      package = prev.phoronix-test-suite;
      net = true;
      dri = true; # for controllers
      binds = [
        {
          from = "~/bwrap/phoronix-test-suite";
          to = "~/";
        }
      ];
    });

  maigret =
    (lib.bwrapIt {
      name = "maigret";
      net = true;
      package = prev.maigret;
      binds = [
        {
          from = "~/bwrap/maigret";
          to = "~/";
        }
      ];
    });

  # keeps connecting in the internet even with the plugins off, so...
  glances =
    (lib.bwrapIt {
      name = "glances";
      net = false;
      dev = true;
      unshare = "";
      package = prev.glances;
    });

  # Generic Bwrap to test configs
  generic-bwrap = (prev.writeScriptBin "wrap"
    ''
      #!${prev.stdenv.shell}
      mkdir -p ~/bwrap/generic_wrap

      exec ${lib.getBin prev.bubblewrap}/bin/bwrap \
        --ro-bind /run /run \
        --ro-bind /bin/sh /bin/sh \
        --ro-bind /bin/sh /bin/bash \
        --ro-bind /etc /etc \
        --ro-bind /nix /nix \
        --ro-bind /sys /sys \
        --ro-bind /var /var \
        --ro-bind /usr /usr \
        --dev /dev \
        --proc /proc \
        --tmpfs /tmp \
        --tmpfs /home \
        --die-with-parent \
        --unshare-all \
        --new-session \
        --bind-try ~/bwrap/generic_wrap ~/ \
        $@
    '');

  ##########
  # UNFREE #
  ##########

  discord =
    (lib.bwrapIt {
      name = "discord";
      # Needs to be the same version of 
      # nix path-info $(which firefox) -r | grep nss-
      package = prev.discord-canary;
      exec = "bin/discordcanary";
      net = true;
      dri = true;
      tmp = true;
      binds = [
        {
          from = "~/bwrap/discord";
          to = "~/";
        }
      ] ++ common_binds ++ data_binds;
      custom_config = [
        # FIXES: "interface 'wl_output' has no event 4"
        # Needs discord to realease with a new electron version
        "--unsetenv NIXOS_OZONE_WL"
      ];
    });

  postman =
    (lib.bwrapIt {
      name = "postman";
      package = prev.postman;
      net = true;
      binds = [
        {
          from = "~/bwrap/postman";
          to = "~/";
        }
      ] ++ code_binds;
    });

  prismlauncher =
    (lib.bwrapIt {
      name = "prismlauncher";
      package = prev.prismlauncher;
      net = true;
      dri = true;
      binds = [
        {
          from = "~/bwrap/prismlauncher";
          to = "~/";
        }
        "~/downloads/curse-forge-mods"
      ];
    });

  #flutter =
  #  let
  #    android = prev.androidenv.composeAndroidPackages {
  #      platformVersions = [ "29" ];
  #      abiVersions = [ "x86_64" ];
  #      buildToolsVersions = [ "29.0.2" ];
  #    };
  #    emulator = prev.androidenv.emulateApp {
  #      name = "emulator";
  #      enableGPU = true;
  #      platformVersion = "28";
  #      abiVersion = "x86_64";
  #    };
  #  in
  #  (lib.bwrapIt {
  #    name = "flutter";
  #    package = prev.flutter;
  #    net = true;
  #    xdg = true;
  #    binds = [
  #      {
  #        from = "~/bwrap/flutter";
  #        to = "~/";
  #      }
  #    ];
  #    custom_config = [
  #      "--setenv ANDROID_JAVA_HOME ${prev.jdk.home}"
  #      "--setenv JAVA_HOME ${prev.jdk.home}"
  #      "--setenv ANDROID_HOME ${android.androidsdk}/libexec/android-sdk"
  #    ];
  #  });

  android-studio-canary =
    (lib.bwrapIt {
      name = "android-studio-canary";
      package = prev.androidStudioPackages.canary;
      xdg = true;
      binds = [
        {
          from = "~/bwrap/android";
          to = "~/";
        }
      ] ++ code_binds;
      custom_config = [
        # FIXES: java.awt.AWTError: Can't connect to X11 window server using ':0' as the value of the DISPLAY variable.
        "--unsetenv _JAVA_AWT_WM_NONREPARENTING"
        "--unsetenv _JAVA_OPTIONS"
        "--unsetenv JDK_JAVA_OPTIONS"
        "--unsetenv AWT_TOOLKIT"
        "--unsetenv XDG_SESSION_TYPE"
        "--unsetenv CLUTTER_BACKEND"
        "--unsetenv QT_QPA_PLATFORM"
        "--unsetenv SDL_VIDEODRIVER"
        "--unsetenv SDL_AUDIODRIVER"
        "--unsetenv NIXOS_OZONE_WL"
      ];
    });
}
