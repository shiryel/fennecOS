{ lib, pkgs, pkgs_unstable, ... }@inputs:

{
  imports = [
    ./common/kitty
    ./common/nvim.nix
    ./common/ranger
  ];

  home.stateVersion = "22.05";

  # automatically calls ssh-add for the ssh-agent
  home.file.".ssh/config".text = "AddKeysToAgent yes"; # no | yes | confirm | ask

  home.file.".zshrc".text = "# Nothing here";

  programs = {
    git = {
      enable = true;
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

  home.enableNixpkgsReleaseCheck = true;

  home.packages = with pkgs; [
    wl-clipboard

    # languages
    pkgs_unstable.elixir
    pkgs_unstable.erlang # needed by elixir
    inotify-tools # needed by erlang
    lxqt.lxqt-openssh-askpass # necessary for mix.deps from private repos
    graphviz
    kotlin
    kotlin-language-server

    # GCC
    gcc
    gdb
    cgdb
    binutils # linker, assemble, etc

    # tools
    direnv
    gnumake
    kubectl
    k9s
    postgresql
    robo3t # mongodb query gui
    tmux # to let change tty owner (ls -l `tty`)
    nodePackages.npm

    podman-compose
    google-cloud-sdk
    kubernetes-helm
  ];
}
