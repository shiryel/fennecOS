function inspect(...)
  -- :message
  return print(vim.inspect(...))
end

function reload_build()
  package.loaded.init = nil
  vim.cmd("luafile $MYVIMRC")
end

vim.g.mapleader = " "
vim.keymap.set("n", "<leader><leader>r", reload_build, {noremap = true, silent = true})

 vim.cmd("colorscheme kanagawa")
