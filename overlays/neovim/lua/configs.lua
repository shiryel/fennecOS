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

local function noremap(bind, command, desc)
  return vim.keymap.set("", bind, command, {noremap = true, silent = true, desc = desc})
end

local function nnoremap(bind, command)
  return vim.api.nvim_set_keymap("n", bind, command, {noremap = true, silent = true})
end

local function nnoremap(bind, command, desc)
  return vim.keymap.set("n", bind, command, {noremap = true, silent = true, desc = desc})
end

local function inoremap(bind, command, desc)
  return vim.keymap.set("i", bind, command, {noremap = true, expr = true, desc = desc})
end

local function cnoremap(bind, command, desc)
  return vim.keymap.set("c", bind, command, {noremap = true, expr = true, desc = desc})
end

local function vnoremap(bind, command, desc)
  return vim.keymap.set("v", bind, command, {noremap = true, silent = true, desc = desc})
end

-- Buffer moves
nnoremap("<c-left>", "<c-w><c-h>")
nnoremap("<c-down>", "<c-w><c-j>")
nnoremap("<c-up>", "<c-w><c-k>")
nnoremap("<c-right>", "<c-w><c-l>")

-- Buffer changes
nnoremap("<leader>be", ":bp<cr>", "previous buffer")
nnoremap("<leader>bo", ":bn<cr>", "next buffer")

-- Remap splits
nnoremap("<leader>vs", ":vs<cr>", "split right")
nnoremap("<leader>vv", ":sp<cr>", "split down")

-- Clipboard
noremap("<leader>y", "\"+y", "system copy")
noremap("<leader>p", "\"+p", "system paste")

-- Save
nnoremap("<leader>w", ":w<cr>", "save")

-- Unselect
nnoremap("<leader>n", ":noh<cr>", "unselect")

-- Convert existing tabs to spaces
nnoremap("<leader><tab>", ":retab<cr>", "tabs to spaces")

-- Open terminal
nnoremap("<leader>T", ":sp <Bar> :terminal<cr> <bar> i", "open terminal")

-- Nvim Tree --
nnoremap("<leader>e", ":NvimTreeFindFile<cr>", "open file tree")
nnoremap("<leader>E", ":NvimTreeToggle<cr>", "toggle file tree")

-- Telescope --
local tb = require('telescope.builtin')
nnoremap("<Leader>sb", tb.buffers, "buffers")
nnoremap("<Leader>sa", tb.live_grep, "everywhere")
nnoremap("<Leader>ss", ":Telescope grep_string search=<cr>", "fzf everywhere")
nnoremap("<Leader>sS", tb.grep_string, "fzf this string")
nnoremap("<Leader>sh", tb.search_history, "telescope history")
nnoremap("<Leader>sH", tb.help_tags, "help tags")
nnoremap("<Leader>st", tb.oldfiles, "old files")
nnoremap("<Leader>sT", tb.tags, "tags")
nnoremap("<Leader>sf", tb.find_files, "files")
nnoremap("<Leader>so", tb.jumplist, "jumps")
nnoremap("<Leader>sr", tb.registers, "registers")
nnoremap("<Leader>sc", tb.commands, "commands")
nnoremap("<Leader>sm", tb.keymaps, "keymaps")
nnoremap("<Leader>s:", tb.command_history, "commands history")
nnoremap("<Leader>s/", tb.search_history, "search history")
nnoremap("<Leader>s'", tb.marks, "marks")
-- git
-- commits: checkout <cr> | reset mixed <C-r>m | reset soft <C-r>s | reset hard <C-r>h
nnoremap("<Leader>gc", tb.git_commits, "commits mixed=<C-r>m soft=<C-r>s hard=<C-r>h")
-- buffer commits: checkout <cr>
nnoremap("<Leader>gb", tb.git_bcommits, "buffer commits")
-- branches: checkout <cr> | track <C-t> | rebase <C-r> | create <C-a> | switch <C-s> | delete <C-d> | merge <C-y>
nnoremap("<Leader>gt", tb.git_branches, "branches track=C-t rebase=C-r create=C-a switch=C-s delete=C-d merge=C-y")
nnoremap("<Leader>gs", tb.git_status, "status")
nnoremap("<Leader>gS", tb.git_stash, "stash")

-- VCoolor --
nnoremap("<leader>c", ":CccPick<CR>", "pick color")

-- Completion Menu --
-- <C-i> - open
-- <C-n> - next
-- <C-p> - previous
-- NOTE: <Tab> == <C-i>
cnoremap("<down>", "wildmenumode() ? \"<c-n>\" : \"<down>\"", "down")
cnoremap("<up>", "wildmenumode() ? \"<c-p>\" : \"<up>\"", "up")

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
