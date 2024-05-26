{ lib, pkgs, ... }:

# Cheatsheet:
# ctrl+h - fzf history
# ctrl+t - fzf cd
# ctrl+f - fzf files
# alt+k  - deer

{
  environment.systemPackages = with pkgs; [
    pure-prompt
    deer
    fd # alternative to find
    lsd # alternative to ls
  ];

  # disable default shellAliases while keeping shellAliases defined in this repo
  # the "mkOverride 1000" is used wrong on the source code, so we need to change the direct values to null
  environment.shellAliases = { ls = null; ll = null; l = null; };

  # search when command not found is on the `programs.zsh.interactiveShellInit` attr
  programs.command-not-found.enable = false;

  # do not ask to create .zshrc when can't find it, as it is passed direct to zsh from /nix/store
  myHM.toAllUsers.home.file.".zshrc".text = "# Nothing here";

  programs = {
    # Zsh global config (super-seeded by home-manager)
    zsh = {
      enable = true;
      histSize = 500000;
      vteIntegration = false;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      # BUG: removed cursor, otherwise it disappears on alacritty
      # - https://github.com/alacritty/alacritty/issues/538
      # - https://github.com/alacritty/alacritty/issues/4975
      #syntaxHighlighting.highlighters = [ "main" "brackets" "pattern" "root" "line" ];

      # /etc/zshenv.local
      shellInit = ''
        # Environment variables from HM
        . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
      '';

      # /etc/zprofile
      loginShellInit = ''
        cat <<EOF >> "$HOME/.logs"
        ================================================
        `date +%m-%d-%Y@%H:%M`
        ================================================
        BOOT INTEGRINITY (to verify after using windows)
        `sha256sum /boot/EFI/systemd/systemd-bootx64.efi`
        `sha256sum /boot/EFI/BOOT/BOOTX64.EFI`
        `sha256sum /boot/EFI/nixos/*initrd.efi`
        `sha256sum /boot/EFI/nixos/*bzImage.efi`
        ================================================
        EOF

        if [ "$(tty)" = "/dev/tty1" ]; then
          mv ".sway_errors.log" "$HOME/.sway_errors.log_old"
          exec sway 2> "$HOME/.sway_errors.log"
          #WLR_RENDERER=vulkan exec sway 2> "$HOME/.sway_errors.log"
        fi
      '';

      # /etc/zshrc
      interactiveShellInit = ''
        ${builtins.readFile ./zshrc}

        # see: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/fzf.nix
        eval "$(${lib.getExe pkgs.fzf} --zsh)"

        export FZF_DEFAULT_COMMAND='${pkgs.fd}/bin/fd --type f --strip-cwd-prefix --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d"

        # (f)ind files
        bindkey -r '^T'
        bindkey '^F' fzf-file-widget

        # cd (t)o directory
        bindkey -r '\ec'
        bindkey '^T' fzf-cd-widget

        # search (h)istory
        bindkey -r '^R'
        bindkey '^H' fzf-history-widget

        eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
        source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

        # dstask completion
        _dstask() {
            compadd -- $(dstask _completions "''${words[@]}")
        }
        
        compdef _dstask dstask
      '';

      # /etc/zshrc
      promptInit = ''
        # Note that to manually override this in ~/.zshrc you should run `prompt off`
        # before setting your PS1 and etc. Otherwise this will likely to interact with
        # your ~/.zshrc configuration in unexpected ways as the default prompt sets
        # a lot of different prompt variables.
        autoload -U promptinit && promptinit && prompt suse && setopt prompt_sp

        if [[ $USER != 'admin' ]]; then
          # Prevents Pure from checking whether the current Git remote
          # has been updated.
          PURE_GIT_PULL=0

          # turn on git stash status
          zstyle :prompt:pure:git:stash show yes
          prompt pure
        fi
      '';
    };
  };
}
