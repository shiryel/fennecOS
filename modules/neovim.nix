{ pkgs, ... }:

{
  # neovim config is on /overlays/overrides/neovim

  environment.systemPackages = with pkgs; [
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
    elixir_ls # Elixir
    nil # Nix
    #ccls # GCC
    zls # Zig
    rust-analyzer # Rust
    #python39Packages.gdtoolkit # GDScript
    python310Packages.python-lsp-server # pylsp
    nodePackages.svelte-language-server
    #vscode-langservers-extracted # JS

    # Formatters
    nixpkgs-fmt # Nix
    rustfmt # Rust

    neovim
    gcc
  ];
}
