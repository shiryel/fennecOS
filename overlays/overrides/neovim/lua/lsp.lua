-- https://learn.microsoft.com/en-us/dotnet/api/microsoft.visualstudio.languageserver.protocol.servercapabilities
local function on_attach(client, bufnr)
  local cap = client.server_capabilities
  -- inspect(cap)

  local function opts(desc) 
    return { noremap = true, silent = true, buffer = bufnr, desc = desc }
  end

  -- COMPLETION --

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- DIAGNOSTICS --

  -- :help vim.diagnostic.*
  local d = vim.diagnostic

  vim.keymap.set("n", "<leader>qq", d.open_float, opts("open diagnostics float window"))
  vim.keymap.set("n", "<leader>ql", d.setloclist, opts("open diagnostics buffer"))
  vim.keymap.set("n", "<leader>qh", d.show, opts("show diagnostics"))
  vim.keymap.set("n", "<leader>qH", d.hide, opts("hide diagnostics"))
  vim.keymap.set("n", "<leader>qn", d.get_next, opts("get next diagnostic"))
  vim.keymap.set("n", "<leader>qp", d.get_prev, opts("get previous diagnostic"))

  -- FORMATING --

  -- :help vim.lsp.*
  local b = vim.lsp.buf

  -- Formats the current buffer
  if cap.documentFormattingProvider then
    -- TODO: add b.format {async = true}
    vim.keymap.set("n", "<leader>f", b.format, opts("format"))
  end
  -- Formats a given range
  if cap.documentRangeFormattingProvider then
    vim.keymap.set("n", "<leader>F", b.range_formatting, opts("format range"))
  end

  -- GO TO --

  -- Jumps to the definition of the symbol under the cursor
  -- Jumps to the declaration of the symbol under the cursor (less used by LSPs)
  if cap.definitionProvider then
    vim.keymap.set("n", "gd", b.definition, opts("go to definition"))
    if cap.declarationProvider then
      vim.keymap.set("n", "gD", b.declaration, opts("go to declaration"))
    else
      vim.keymap.set("n", "gD", b.definition, opts("go to definition"))
    end
  else
    if cap.declarationProvider then
      vim.keymap.set("n", "gd", b.declaration, opts("go to declaration"))
      vim.keymap.set("n", "gD", b.declaration, opts("go to declaration"))
    end
  end
  -- Jumps to the definition of the type of the symbol under the cursor
  if cap.typeDefinitionProvider then
    vim.keymap.set("n", "<leader>t", b.type_definition, opts("go to type definition"))
  end
  -- Lists all the references to the symbol under the cursor in the quickfix window
  if cap.referenceProvider then
    vim.keymap.set("n", "<leader>r", b.references, opts("list references to symbol"))
  end

  -- HELPERS --

  -- Displays hover information about the symbol under the cursor in a floating
  -- window. Calling the function twice will jump into the floating window
  if cap.hoverProvider then
    vim.keymap.set("n", "<leader>h", b.hover, opts("show symbol info"))
  end
  -- Displays signature information about the symbol under the cursor in a
  -- floating window
  if cap.signatureHelpProvider then
    vim.keymap.set("n", "<leader>H", b.signature_help, opts("show symbol signature"))
  end
  -- Lists all the implementations for the symbol under the cursor in the
  -- quickfix window
  if cap.implementationProvider then
    vim.keymap.set("n", "<leader>i", b.implementation, opts("list symbol's implementations"))
  end

  -- WORKSPACES --

  -- Add the folder at path to the workspace folders. If {path} is not
  -- provided, the user will be prompted for a path using |input()|
  --if cap.foldingRangeProvider then
  if cap.workspaceClientCapabilities then
    vim.keymap.set("n", "<leader>wa", b.add_workspace_folder, opts("add workspace folder"))
    vim.keymap.set("n", "<leader>wl", b.list_workspace_folders, opts("list workspace folders"))
    vim.keymap.set("n", "<leader>wd", b.remove_workspace_folder, opts("remove workspace folder"))
  end
  -- Lists all symbols in the current workspace in the quickfix window.
  -- The list is filtered against {query}; if the argument is omitted from the
  -- call, the user is prompted to enter a string on the command line. An empty
  -- string means no filtering is done
  if cap.workspaceSymbolProvider then
    vim.keymap.set("n", "<leader>ws", b.workspace_symbol, opts("list symbols on workspace"))
  end

  -- RENAME --

  -- Renames all references to the symbol under the cursor
  if cap.renameProvider then
    vim.keymap.set("n", "<leader>rn", b.rename, opts("rename all references"))
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

-- ELIXIR
lspconfig.elixirls.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"elixir-ls"}
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
lspconfig.rnix.setup({
  on_attach = on_attach, 
  capabilities = capabilities(), 
  cmd = {"rnix-lsp"}
})

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
