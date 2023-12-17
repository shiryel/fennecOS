-- https://learn.microsoft.com/en-us/dotnet/api/microsoft.visualstudio.languageserver.protocol.servercapabilities
local function on_attach(client, bufnr)
  local fzf = require('fzf-lua')
  local cap = client.server_capabilities
  -- inspect(cap)

  local function noremap(bind, command, desc)
    return vim.keymap.set("n", bind, command, {buffer = bufnr, silent = true, noremap = true, desc = desc})
  end

  -- COMPLETION --

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- DIAGNOSTICS --

  -- :help vim.diagnostic.*
  local d = vim.diagnostic

  --noremap("<leader>qq", tb.diagnostics, "open diagnostics float window")
  noremap("<leader>qq", fzf.diagnostics_document, "open diagnostics float window")
  noremap("<leader>ql", d.setloclist, "open diagnostics buffer")
  noremap("<leader>qh", d.show, "show diagnostics")
  noremap("<leader>qH", d.hide, "hide diagnostics")
  noremap("<leader>qn", d.get_next, "get next diagnostic")
  noremap("<leader>qp", d.get_prev, "get previous diagnostic")

  -- FORMATING --

  -- :help vim.lsp.*
  local b = vim.lsp.buf

  -- Formats the current buffer
  if cap.documentFormattingProvider then
    noremap("<leader>f", b.format, "format")
  end
  -- Formats a given range
  if cap.documentRangeFormattingProvider then
    noremap("<leader>F", b.range_formatting, "format range")
  end

  -- LOCATIONS --

  -- see: https://github.com/ibhagwan/fzf-lua/issues/669
  noremap("ga", fzf.lsp_finder, "All LSP locations, combined view")

  -- Lists all the references to the symbol under the cursor in the quickfix window
  --if cap.referenceProvider then
  --  noremap("<leader>r", tb.lsp_references, "list references to symbol")
  --end

  -- Lists all the implementations for the symbol under the cursor in the
  -- quickfix window
  --if cap.implementationProvider then
  --  noremap("<leader>i", tb.lsp_implementations, "list symbol's implementations")
  --end

  --if cap.typeDefinitionProvider then
  --  noremap("<leader>t", fzf.lsp_type_definitions, "go to type definition")
  --end

  -- GOTO --
  
  -- Jumps to the definition of the symbol under the cursor
  -- Jumps to the declaration of the symbol under the cursor (less used by LSPs)
  if cap.definitionProvider then
    noremap("gd", b.definition, "go to definition")
    if cap.declarationProvider then
      noremap("gD", b.declaration, "go to declaration")
    else
      noremap("gD", b.definition, "go to definition")
    end
  else
    if cap.declarationProvider then
      noremap("gd", b.declaration, "go to declaration")
      noremap("gD", b.declaration, "go to declaration")
    end
  end

  -- HELPERS --

  -- Displays hover information about the symbol under the cursor in a floating
  -- window. Calling the function twice will jump into the floating window
  if cap.hoverProvider then
    noremap("<leader>h", b.hover, "show symbol info")
  end

  -- Displays signature information about the symbol under the cursor in a
  -- floating window
  if cap.signatureHelpProvider then
    noremap("<leader>H", b.signature_help, "show symbol signature")
  end

  -- WORKSPACES --

  -- Add the folder at path to the workspace folders. If {path} is not
  -- provided, the user will be prompted for a path using |input()|
  --if cap.foldingRangeProvider then
  if cap.workspaceClientCapabilities then
    noremap("<leader>wa", b.add_workspace_folder, "add workspace folder")
    noremap("<leader>wl", b.list_workspace_folders, "list workspace folders")
    noremap("<leader>wd", b.remove_workspace_folder, "remove workspace folder")
  end
  -- Lists all symbols in the current workspace in the quickfix window.
  -- The list is filtered against {query}; if the argument is omitted from the
  -- call, the user is prompted to enter a string on the command line. An empty
  -- string means no filtering is done
  if cap.workspaceSymbolProvider then
    noremap("<leader>ws", b.workspace_symbol, "list symbols on workspace")
  end

  -- RENAME --

  -- Renames all references to the symbol under the cursor
  if cap.renameProvider then
    noremap("<leader>rn", b.rename, "rename all references")
  end

  -- HIGHLIGHT --

  -- Send request to the server to resolve document highlights for the current
  -- text document position. This request can be triggered by a key mapping or
  -- by events such as `CursorHold`, e.g.:
  --   autocmd CursorHold  <buffer> lua b.document_highlight()
  --   autocmd CursorHoldI <buffer> lua b.document_highlight()
  --   autocmd CursorMoved <buffer> lua b.clear_references()
  --
  -- Note: Usage of |b.document_highlight()| requires the following
  -- highlight groups to be defined or you won't be able to see the actual
  -- highlights: hl-LspReferenceText, hl-LspReferenceRead, hl-LspReferenceWrite
  if cap.documentHighlightProvider then
    vim.api.nvim_create_augroup("lsp_document_highlight", { clear = true })
    vim.api.nvim_clear_autocmds { buffer = bufnr, group = "lsp_document_highlight" }
    vim.api.nvim_create_autocmd("CursorHold", {
        callback = b.document_highlight,
        buffer = bufnr,
        group = "lsp_document_highlight",
        desc = "Document Highlight",
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
        callback = b.clear_references,
        buffer = bufnr,
        group = "lsp_document_highlight",
        desc = "Clear All the References",
    })
  end
end

local function capabilities()
  return require("cmp_nvim_lsp").default_capabilities()
end

-- vim.lsp.set_log_level("debug")

local lspconfig = require("lspconfig")
local lsp_util = require 'lspconfig.util'

-- ELIXIR
lspconfig.elixirls.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"elixir-ls"},
  root_dir = function(fname)
    -- find mix.exs before git, as sometimes we have a project on a subdirectory
    return lsp_util.root_pattern 'mix.exs'(fname) or lsp_util.find_git_ancestor(fname) or vim.loop.os_homedir()
  end,
})

-- GDSCRIPT
lspconfig.gdscript.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  flags = {debounce_text_changes = 50}
})

-- GDSCRIPT formater
lspconfig.efm.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  filetypes = {"gdscript"}, 
  flags = {debounce_text_changes = 50}, 
  init_options = {documentFormatting = true}, 
  settings = {
    rootMarkers = {"project.godot", ".git/"}, 
    lintDebounce = 100, 
    languages = {
      gdscript = {
        formatCommand = "gdformat -l 100", 
        formatStdin = true
      }
    }
  },
  cmd = {"efm-langserver"}
})

-- LUA
lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities(),
  cmd = {"lua-language-server"}
})

-- ZIG
lspconfig.zls.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"zls"}
})

-- KOTLIN
lspconfig.kotlin_language_server.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"kotlin-language-server"}
})

-- NIX
lspconfig.nil_ls.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"nil"},
  settings = {
    ['nil'] = {
      formatting = {
        command = {"nixpkgs-fmt"}
      },
      nix = {
        flake = {
          autoEvalInputs = true
        },
        maxMemoryMB = 4096
      }
    }
  }
})

-- NIX
-- TODO: wait until nixd have better integration with flakes
-- https://github.com/nix-community/nixd/blob/main/docs/user-guide.md
--lspconfig.nixd.setup({
--  on_attach = on_attach, 
--  capabilities = capabilities(), 
--  cmd = {"nixd"},
--  settings = {
--    ['nixd'] = {
--      formatting = {
--        command = {"nixpkgs-fmt"}
--      },
--      eval = {
--        target = {
--          args = { };
--          installable = "";
--        },
--        depth = 3,
--        workers = 3
--      },
--      options = {
--        enable = true,
--        target = {
--          args = { },
--          installable = ".#nixosConfigurations.default.options"
--        }
--      }
--    }
--  }
--})

-- C
lspconfig.clangd.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"clangd", "--background-index", "--enable-config"}
  --cmd = {"ccls"}
})

-- RUST
lspconfig.rust_analyzer.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"rust-analyzer"}
})

-- HASKELL
lspconfig.hls.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"haskell-language-server"}
})

-- PYTHON
lspconfig.pylsp.setup({
  on_attach = on_attach, 
  capabilities = capabilities(),
  cmd = {"pylsp"}
})

-- JS
lspconfig.eslint.setup({
  on_attach = on_attach, 
  capabilities = capabilities(),
})

-- SVELTE
lspconfig.svelte.setup({
  on_attach = on_attach, 
  capabilities = capabilities(),
})

-- TYPST
lspconfig.typst_lsp.setup({
  on_attach = on_attach,
  capabilities = capabilities(),
  root_dir = function(fname)
    return lsp_util.root_pattern '.git'(fname) or lsp_util.path.dirname(fname)
  end
})

-- DART
-- NOTE: May need the command `dart pub get` to work correctly
--
--require("flutter-tools").setup {
--  lsp = {
--    --color = { -- show the derived colours for dart variables
--    --  enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
--    --  background = true, -- highlight the background
--    --  background_color = nil, -- required, when background is transparent (i.e. background_color = { r = 19, g = 17, b = 24},)
--    --  foreground = false, -- highlight the foreground
--    --  virtual_text = true, -- show the highlight using virtual text
--    --  virtual_text_str = "■", -- the virtual text character to highlight
--    --},
--    on_attach = on_attach,
--    capabilities = capabilities(),
--    flutter_lookup_cmd = "dirname $(which flutter)"
--  }
--}
lspconfig.dartls.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = { 'dart', 'language-server', '--protocol=lsp' }
})
