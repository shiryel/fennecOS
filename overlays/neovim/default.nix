final: prev:
let
  nvim-focus = prev.vimUtils.buildVimPlugin {
    pname = "focus-nvim";
    version = "git";
    src = prev.fetchFromGitHub {
      owner = "nvim-focus";
      repo = "focus.nvim";
      rev = "31f41d91b6b331faa07f0a513adcbc37087d028d";
      sha256 = "sha256-IOMhyplEyLEPJ/oXFjOfs7uXY52AcVrSZuHV7t4NeUE=";
    };
  };
in
{
  neovim = (prev.neovim.override {
    configure = {
      # will be passed to the -u option of nvim
      # do `cat .../bin/nvim` to find the `...-init.vim` (after -u) then
      # do a cat on it to see the file loading the plugins
      customRC = ''
        lua << EOF
          ${builtins.readFile ./lua/init.lua}

          ${builtins.readFile ./lua/plugins.lua}
          ${builtins.readFile ./lua/lsp.lua}
          ${builtins.readFile ./lua/configs.lua}
        EOF
      '';
      # myPlugins can be any name
      packages.myPlugins = {
        # loaded on launch
        start = with prev.vimPlugins; [
          #
          # THEME
          #
          # maybe change to Tomorrow Night (Bright) [the default of alacritty] ?
          #vim-code-dark
          kanagawa-nvim
          #
          # LSP
          #
          nvim-lspconfig
          aerial-nvim
          #flutter-tools-nvim # sets up dartls + flutter utils
          #
          # COMPLETION
          #
          nvim-cmp
          cmp-nvim-lsp
          cmp-nvim-lsp-document-symbol # type of the symbol
          cmp-nvim-lsp-signature-help # params autocompletion
          cmp-nvim-lua # lua completion
          cmp-buffer
          cmp-path
          vim-vsnip # required by cmp
          #cmp-omni
          cmp-cmdline
          #
          # SYNTAX HIGHLIGHT
          #
          #(nvim-treesitter.withPlugins (plugins: tree-sitter.allGrammars))
          # remove in nvim 0.10 ? (https://github.com/nvim-telescope/telescope.nvim/issues/2498)
          (nvim-treesitter.withPlugins (plugins: with plugins; [
            # common
            tree-sitter-markdown
            tree-sitter-comment
            # languages
            tree-sitter-elixir
            tree-sitter-heex
            tree-sitter-erlang
            tree-sitter-nix
            tree-sitter-rust
            tree-sitter-c
            tree-sitter-cpp
            tree-sitter-llvm
            tree-sitter-clojure
            tree-sitter-commonlisp
            #tree-sitter-kotlin
            tree-sitter-zig
            tree-sitter-lua
            tree-sitter-elm
            tree-sitter-haskell
            tree-sitter-dart
            tree-sitter-gdscript
            tree-sitter-godot-resource
            tree-sitter-typst
            # web
            tree-sitter-svelte
            tree-sitter-javascript
            tree-sitter-typescript
            tree-sitter-html
            tree-sitter-css
            tree-sitter-scss
            # tools
            tree-sitter-vim
            tree-sitter-dot
            tree-sitter-cmake
            tree-sitter-make
            tree-sitter-dockerfile
            tree-sitter-yaml
            tree-sitter-toml
            tree-sitter-json
            tree-sitter-regex
            tree-sitter-graphql
          ]))
          kotlin-vim
          typst-vim
          #nvim-treesitter-textobjects
          #
          # GIT
          #
          gitsigns-nvim
          diffview-nvim
          #
          # NAVIGATION
          #
          nvim-tree-lua
          nvim-web-devicons
          fzf-lua
          #plenary-nvim
          #telescope-nvim
          #telescope-fzf-native-nvim
          #nvim-focus
          #
          # EXTRA
          #
          which-key-nvim
          ccc-nvim
        ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ ];
      };
    };
  });
}
