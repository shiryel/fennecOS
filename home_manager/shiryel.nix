{ lib, pkgs, pkgs_unstable, ... }@inputs:

{
  imports = [
    ./common/alacritty
    ./common/firefox
    ./common/imv
    ./common/kitty
    ./common/mako
    ./common/mangohud
    ./common/nvim.nix
    ./common/oguri
    ./common/ranger
    ./common/sway
    ./common/waybar
    ./common/wofi
    ./common/theme.nix
    ./common/xdg.nix
  ];

  home.stateVersion = "22.05";

  # automatically calls ssh-add for the ssh-agent
  #home.file.".ssh/config".text = "AddKeysToAgent yes"; # no | yes | confirm | ask

  home.file.".zshrc".text = ''
    # eval "$(${pkgs.starship}/bin/starship init zsh)"
  '';

  programs = {
    git = {
      enable = true;
      userName = "Shiryel";
      userEmail = "contact@shiryel.com";
      signing = {
        key = "AB634CD93322BD426231F764C4041EA6B32633DE";
        signByDefault = false;
      };
      extraConfig = {
        init = {
          defaultBranch = "master";
          pull.rebase = true;
          push.default = "current";
        };
      };
      aliases = {
        commend = "commit --amend --no-edit";
        grog = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
        please = "push --force-with-lease";
        root = "rev-parse --show-toplevel";
      };
      ignores = [ ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  services.opensnitch-ui.enable = true;

  home.enableNixpkgsReleaseCheck = true;

  # More examples of pkgs at:
  # https://nixos.wiki/wiki/I3
  home.packages = with pkgs; [
    # Games
    airshipper

    # Themes
    lxappearance

    # Files
    # NOTE: In case that the video previews are not working,
    # remove the fail/ on .cache/thumbnails/
    cinnamon.nemo
    libsForQt5.gwenview
    ffmpeg # (ranger, nautilus)
    ffmpegthumbnailer # (ranger, nautilus)
    android-file-transfer
    jmtpfs # (android-file-transfer)

    # Video / Audio
    mpv
    cmus
    pavucontrol
    #helvum # pipewire control
    easyeffects # pipewire effects
    yt-dlp

    # Editors
    krita
    #gmic-qt
    #gmic-qt-krita
    pkgs_unstable.godot_4
    blender
    openshot-qt # Video editor
    libreoffice
    #orca-c
    #sonic-pi
    #carla # ardour lmms
    pkgs_unstable.helix

    # Tools
    direnv
    gnumake
    kubectl
    k9s
    postgresql
    dbeaver
    robo3t # mongodb query gui
    nixpkgs-review
    #vagrant
    #ansible
    exercism
    pandoc
    nodePackages.npm

    # Languages
    pkgs_unstable.elixir
    erlang # needed by elixir
    inotify-tools # needed by erlang
    graphviz
    nodejs
    yarn
    pkgs_unstable.rustc
    pkgs_unstable.cargo

    # GCC
    #gcc
    gdb
    cgdb
    #binutils # linker, assemble, etc
    # This can help in the future: https://github.com/Mic92/nix-ld

    # CLANG
    # XXX: the order of include matters (on flake.nix at least)
    #clang-tools_14
    #clang_14 # clang + clangd
    #lldb_14
    #lld

    # Android
    # NOTE: for android toolchain you need to open and intall it throught android-studio
    # NOTE: to accept the license: https://stackoverflow.com/questions/61993738/flutter-doctor-android-licenses-gives-a-java-error
    #flutter
    android-tools
    #jdk
  ];
}
