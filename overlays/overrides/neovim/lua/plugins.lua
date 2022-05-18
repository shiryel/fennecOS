-- Icons for CMP
local kind_icons = {
  Text = "",
  Method = "",
  Function = "",
  Constructor = "",
  Field = "",
  Variable = "",
  Class = "ﴯ",
  Interface = "",
  Module = "",
  Property = "ﰠ",
  Unit = "",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "",
  Event = "",
  Operator = "",
  TypeParameter = ""
}

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args) 
      vim.fn["vsnip#anonymous"](args.body) 
    end
  },
  window = {
    completion = cmp.config.window.bordered(), 
    documentation = cmp.config.window.bordered()
  },
  view = {            
    entries = "custom" -- can be "custom", "wildmenu" or "native"
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-up>'] = cmp.mapping.scroll_docs(-4),
    ['<C-down>'] = cmp.mapping.scroll_docs(4),
    ["<C-tab>"] = cmp.mapping.complete(), 
    ["<CR>"] = cmp.mapping.confirm({select = true})
    -- ['<C-c>'] = cmp.mapping.abort(),
  }),
  sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = 'nvim_lsp_signature_help' },
      { name = 'buffer' },
      { name = 'path' },
      --{ name = 'omni' },
      { name = "vsnip" },
      { name = 'nvim_lua' }
    },
    {{name = "buffer"}}
  ),
  formatting = {
    format = function(entry, vim_item)
      -- Kind icons
      vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
      -- Source
      vim_item.menu = ({
        buffer = "[Buffer]",
        nvim_lsp = "[LSP]",
        luasnip = "[LuaSnip]",
        nvim_lua = "[Lua]",
        latex_symbols = "[LaTeX]",
      })[entry.source.name]
      return vim_item
    end
  }
})

cmp.setup.cmdline('/', {
  sources = cmp.config.sources({
    { name = 'nvim_lsp_document_symbol' }
  }, {
    { name = 'buffer' }
  })
})

require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true, 
    additional_vim_regex_highlighting = { "kotlin" }
  },
  textobjects = {
    enable = true
  },
  incremental_selection = {
    enable = true, 
    keymaps = {
      init_selection = "gnn", 
      node_incremental = "grn", 
      scope_incremental = "grc", 
      node_decremental = "grm"}
  }, 
  indent = {
    enable = true, 
    disable = { "gdscript", "elixir" } -- gdscript ident dont work
  }
})

require("nvim-tree").setup({
  disable_netrw = true,
  hijack_netrw = false,
  sort_by = "case_sensitive",
  sync_root_with_cwd = true, -- may change root when dir change
  respect_buf_cwd = true, -- change to cwd when opening
  update_focused_file = {
    enable = true,
    update_root = false
  },
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = ""
    }
  },
  modified = {
    enable = true
  },
  view = {
    hide_root_folder = true,
    width = 30,
    mappings = {
      list = {
        { key = "<C-up>", action = "dir_up" },
        { key = "s", action = "vsplit" },
        { key = "v", action = "split" },
        { key = "?", action = "toggle_help" },
      },
    },
  },
  renderer = {
    add_trailing = true
  },
  filters = {
    dotfiles = true
  },
  actions = {
    open_file = {
      quit_on_open = true
    }
  },
  tab = {
    sync = {
      open = true,
      close = true
    }
  }
})

require("gitsigns").setup({
  numhl = true, 
  signcolumn = false, 
  current_line_blame = true, 
  attach_to_untracked = true, 
  sign_priority = 6, 
  update_debounce = 100, 
  status_formatter = nil, -- use default
  -- use_internal_diff = true,
  max_file_length = 40000, 
  preview_config = {
    -- Options passed to nvim_open_win
    border = "single", 
    style = "minimal", 
    relative = "cursor", 
    row = 0, 
    col = 1
  }
})

require("which-key").setup({
  plugins = {
    marks = true, 
    registers = true, 
    spelling = {
      enabled = true, 
      suggestions = 20
    }
  },
  ignore_missings = false, 
  triggers_blacklist = {i = {"j", "k"}, v = {"j", "k"}}
})

require("ccc").setup({
  highlighter = {
    auto_enable = true
  }
})
