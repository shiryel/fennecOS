{ lib, pkgs, pkgs_unstable, ... }@inputs:

{
  home.packages = with pkgs; [
    # Syntax Highlight
    tree-sitter
    # for fzf-vim
    bat
    delta

    # Finders
    fzf # (fzf-vim)
    perl # (fzf-vim)
    silver-searcher
    ripgrep

    # Language servers
    efm-langserver # General Purpose LSP
    pkgs_unstable.elixir_ls # Elixir
    rnix-lsp # Nix
    #ccls # GCC
    zls # Zig
    pkgs_unstable.rust-analyzer # Rust
    #python39Packages.gdtoolkit # GDScript
    nodePackages.svelte-language-server
    nodePackages.vscode-langservers-extracted # JS

    # Formatters
    nixpkgs-fmt # Nix
    rustfmt # Rust

    pkgs_unstable.neovim
    gcc
  ];
}
