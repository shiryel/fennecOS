-------------
-- Options --
-------------

local g = vim.g
local o = vim.opt
local c = vim.cmd

c("syntax enable")
c("highlight Comment cterm=italic")
c("hi link xmlEndTag xmlTag")
c("hi htmlArg gui=italic")
c("hi Comment gui=italic")
c("hi Type gui=italic")
c("hi htmlArg cterm=italic")
c("hi Comment cterm=italic")
c("hi Type cterm=italic")

-- Transparent Background
c("highlight Normal guibg=none")
c("highlight NonText guibg=none")

if g.neovide then
  g.neovide_hide_mouse_when_typing = 1
end

o.guifont = {"Cousine Nerd Font Mono", ":h11"}

-- to work with 16M colors schemes in the terminal
o.termguicolors = true

-- Spaces and Tabs
o.syntax = "enable"
o.expandtab = true
o.tabstop = 2 -- Spaces that a tab counts for
o.softtabstop = 2 -- Spaces that a tab counts when editing
o.shiftwidth = 2 -- Spaces to use for each step of (auto)indent

-- UI Config
o.encoding = "utf8"
o.inccommand = "nosplit" -- give us a realtime preview of substitution before we send it "set list " show formating characters
o.lcs = "eol:\194\172,extends:\226\157\175,precedes:\226\157\174,tab:>-" -- the formating characters
o.number = true
o.relativenumber = true -- line number is relative to cursor
o.mouse = "a" -- enable mouse
o.cursorline = false -- dont highlight the current cursor line
o.smartindent = true -- smart ident (priority for C like langs)
o.autoindent = true -- copy the ident of current line when using the o or O commands
o.wrap = true -- continue long lines in the next line
o.linebreak = true
o.lazyredraw = true -- screen will not redrawn while exec macros, registers or not typed commands
o.showmatch = true -- jump to a match when executed
o.showmode = false -- lightline shows the status not vim
o.showtabline = 2 -- always show files with tab page labels
o.shortmess = "ac" -- avoid hit-enter prompts, a = abbreviation without loss, c = avoid showing message extra message when using completion
o.updatetime = 300 -- time (ms) to save in swap.  You will have bad experience for diagnostic messages when it's default 4000.
o.signcolumn = "no" -- hide the column for error signs
o.showcmd = true -- show commands in the last line off screen
o.cmdheight = 2 -- better display for messages
o.scrolloff = 10 -- centers the cursor when moving

-- StatusLine
-- F to full name
o.statusline = "%f%m%r%h%w %=%< [%Y] [0x%02.2B]%4v,%4l %3p%% of %L"
o.ruler = false -- hide the column and line of the pointer
o.laststatus = 2 -- always shows the status line on other windows

-- Folding
o.foldenable = true -- use zi to togle folding
o.foldlevelstart = 0 -- some folds closed when start editing
o.foldnestmax = 10 -- limit the folds in the indent and syntax

o.backup = false -- no backup file when overwriting
o.writebackup = false -- no make backup before overwriting
o.swapfile = true -- enable swapfile (dont use it with confidential information, that even root must not be able to acess!)
o.shortmess = "A" -- don't give the "ATTENTION" message when an existing swap file is found.
o.hidden = true -- buffer continue to exists when the file is abandoned
o.history = 100 -- history of the : commands
do end (o.path):append({"**"}) -- list of directories which will be searched when using the |gf|, [f, ]f, ^Wf, |:find|, |:sfind|, |:tabfind| and other commands
o.splitbelow = true -- default split below
o.diffopt = "vertical" -- default diff split in the vertical

-- Searching
o.incsearch = true -- show when typing
o.hlsearch = true -- highlight
o.smartcase = false -- do not override the ignorecase option
o.ignorecase = true -- ignorecase option :P

-- completion
o.wildmenu = true -- menu inline
o.wildmode = "full,list:lastused" -- full fist because is how the plugin works
o.completeopt = "menu,menuone,preview,noselect,noinsert"

-- ignore on tab completing
vim.opt.wildignore:append({"*.o", "*~", ".**", "build/**", "log/**", "tmp/**"})

-- Set <Leader>
g.mapleader = " "

-------------
-- Configs --
-------------

local function nnoremap(bind, command)
  return vim.api.nvim_set_keymap("n", bind, command, {noremap = true, silent = true})
end

local function inoremap(bind, command)
  return vim.api.nvim_set_keymap("i", bind, command, {noremap = true, expr = true})
end

local function cnoremap(bind, command)
  return vim.api.nvim_set_keymap("c", bind, command, {noremap = true, expr = true})
end

local function noremap(bind, command)
  return vim.api.nvim_set_keymap("", bind, command, {noremap = true, silent = true})
end

-- Load ned configs
nnoremap("<leader><Leader>r", ":lua reload()<cr>")

-- Buffer moves
nnoremap("<leader>bn", ":ls<cr>")
nnoremap("<leader>be", ":bp<cr>")
nnoremap("<leader>bo", ":bn<cr>")
nnoremap("<leader>bi", ":e;<cr>")

-- Spit moves
nnoremap("<c-left>", "<c-w><c-h>")
nnoremap("<c-down>", "<c-w><c-j>")
nnoremap("<c-up>", "<c-w><c-k>")
nnoremap("<c-right>", "<c-w><c-l>")

-- Remap splits
noremap("<leader>vs", ":vs<cr>")
noremap("<leader>vv", ":sp<cr>")

-- Clipboard
noremap("<leader>y", "\"+y")
noremap("<leader>p", "\"+p")

-- Save
nnoremap("<leader>w", ":w<cr>")

-- Deselect
nnoremap("<leader>n", ":noh<cr>")

-- Convert existing tabs
nnoremap("<leader><tab>", ":retab<cr>")

-- Open terminal
nnoremap("<leader>T", ":sp <Bar> :terminal<cr> <bar> i")

-- Nvim Tree --
noremap("<leader>e", ":NvimTreeFindFile<cr>")
noremap("<leader>E", ":NvimTreeToggle<cr>")

-- Vim Sneak --
g["sneak#label"] = 1

-- FZF --
-- ignore file names on Ag result
--c("command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)")
c("command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)")
-- Ag result, ALL
noremap("<Leader>sa", ":Ag<CR>")
-- Rg result, Search inside ALL
noremap("<Leader>ss", ":Rg<CR>")
-- Search on git versioned files
noremap("<Leader>sf", ":GFiles<CR>")
-- Search on all files
noremap("<Leader>sF", ":Files<CR>")
-- Search on the buffer history
noremap("<Leader>sb", ":Buffers<CR>")
-- Search on the file history
noremap("<Leader>sh", ":History<CR>")
-- Search on the buffer tags
noremap("<Leader>st", ":BTags<CR>")
-- Search through the gutertags
noremap("<Leader>sT", ":Tags<CR>")
-- Serach for the sintax file type
noremap("<Leader>st", ":Filetypes<CR>")
-- Search the buffer lines " like ag
noremap("<Leader>sl", ":BLines<CR>")
-- Search the lines " like /
noremap("<Leader>sL", ":Lines<CR>")
-- Search for the marks
noremap("<Leader>s'", ":Marks<CR>")
-- Shearch for help tags with full scren (! tag)
noremap("<Leader>sH", ":Helptags!<CR>")
-- Search for commands
noremap("<Leader>sc", ":Commands<CR>")
-- Search for the : history
noremap("<Leader>s:", ":History:<CR>")
-- Search for the / history
noremap("<Leader>s/", ":History/<CR>")
-- Search for maps
noremap("<Leader>sM", ":Maps<CR>")

-- VCoolor --
nnoremap("<leader>c", ":CccPick<CR>")

-- Completion Menu --
-- <C-i> - open
-- <C-n> - next
-- <C-p> - previous
-- NOTE: <Tab> == <C-i>
cnoremap("<down>", "wildmenumode() ? \"<c-n>\" : \"<down>\"")
cnoremap("<up>", "wildmenumode() ? \"<c-p>\" : \"<up>\"")

c("au BufRead,BufNewFile *.colortemplate set filetype=colortemplate")

c("au BufRead,BufNewFile *.fnl set filetype=clojure")
c("au BufRead,BufNewFile *.ex set filetype=elixir")
c("au BufRead,BufNewFile *.exs set filetype=elixir")
c("au BufRead,BufNewFile *.slime set filetype=elixir")
c("au BufRead,BufNewFile *.zig set filetype=zig")

c("au FileType elm set tabstop=4")
c("au FileType elm set shiftwidth=4")
c("au FileType elm set expandtab")

c("au FileType elm set tabstop=2")
c("au FileType elm set shiftwidth=2")
c("au FileType gdscript set noexpandtab")
