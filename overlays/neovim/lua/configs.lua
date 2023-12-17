-------------
-- Options --
-------------

local g = vim.g
local o = vim.opt
local c = vim.cmd

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

o.guifont = { "Cousine Nerd Font Mono", ":h11" }

-- to work with 16M colors schemes in the terminal
o.termguicolors = true

-- Spaces and Tabs
o.syntax = "enable"
o.expandtab = true
o.tabstop = 2     -- Spaces that a tab counts for
o.softtabstop = 2 -- Spaces that a tab counts when editing
o.shiftwidth = 2  -- Spaces to use for each step of (auto)indent

-- UI Config
o.encoding = "utf8"
o.number = true
o.relativenumber = true -- line number is relative to cursor
o.mouse = "a"           -- enable mouse
o.cursorline = false    -- dont highlight the current cursor line
o.smartindent = true    -- smart ident (priority for C like langs)
o.autoindent = true     -- copy the ident of current line when using the o or O commands
o.wrap = true           -- continue long lines in the next line
o.linebreak = true
o.lazyredraw = true     -- screen will not redrawn while exec macros, registers or not typed commands
o.showmatch = true      -- jump to a match when executed
o.showmode = false      -- lightline shows the status not vim
o.showtabline = 2       -- always show files with tab page labels
o.shortmess =
"ac"                    -- avoid hit-enter prompts, a = abbreviation without loss, c = avoid showing message extra message when using completion
o.updatetime = 300      -- time (ms) to save in swap.  You will have bad experience for diagnostic messages when it's default 4000.
o.signcolumn = "no"     -- hide the column for error signs
o.showcmd = true        -- show commands in the last line off screen
o.cmdheight = 2         -- better display for messages
o.scrolloff = 10        -- centers the cursor when moving
-- give us a realtime preview of substitution before we send it "set list " show formating characters
o.inccommand = "nosplit"
o.lcs = "eol:\194\172,extends:\226\157\175,precedes:\226\157\174,tab:>-" -- the formating characters

-- StatusLine
-- F to full name
o.statusline = "%f%m%r%h%w %=%< [%Y] [0x%02.2B]%4v,%4l %3p%% of %L"
o.ruler = false  -- hide the column and line of the pointer
o.laststatus = 2 -- always shows the status line on other windows

-- Backup / History
o.backup = false          -- no backup file when overwriting
o.writebackup = false     -- no make backup before overwriting
o.swapfile = true         -- enable swapfile (dont use it with confidential information, that even root must not be able to acess!)
o.shortmess = "A"         -- don't give the "ATTENTION" message when an existing swap file is found.
o.hidden = true           -- buffer continue to exists when the file is abandoned
o.history = 100           -- history of the : commands
do end
(o.path):append({ "**" }) -- list of directories which will be searched when using the |gf|, [f, ]f, ^Wf, |:find|, |:sfind|, |:tabfind| and other commands

-- Split / Diff
o.splitbelow = true       -- default split below
o.diffopt = "vertical"    -- default diff split in the vertical

-- Searching
o.incsearch = true  -- show when typing
o.hlsearch = true   -- highlight
o.smartcase = false -- do not override the ignorecase option
o.ignorecase = true -- ignorecase option :P

-- completion
o.wildmenu = true                 -- menu inline
o.wildmode = "full,list:lastused" -- full fist because is how the plugin works
o.completeopt = "menu,menuone,preview,noselect,noinsert"

-- ignore on tab completing
vim.opt.wildignore:append({ "*.o", "*~", ".**", "build/**", "log/**", "tmp/**" })

-- Set <Leader>
g.mapleader = " "

-------------
-- Configs --
-------------

local function noremap(bind, command, desc)
  return vim.keymap.set("", bind, command, { noremap = true, silent = true, desc = desc })
end

local function nnoremap(bind, command, desc)
  return vim.keymap.set("n", bind, command, { noremap = true, silent = true, desc = desc })
end

local function inoremap(bind, command, desc)
  return vim.keymap.set("i", bind, command, { noremap = true, expr = true, desc = desc })
end

local function cnoremap(bind, command, desc)
  return vim.keymap.set("c", bind, command, { noremap = true, expr = true, desc = desc })
end

local function vnoremap(bind, command, desc)
  return vim.keymap.set("v", bind, command, { noremap = true, silent = true, desc = desc })
end

-- Folding
-- (we use aerial to navigate and fold to handle HTML)
o.foldmethod = "expr"
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldenable = false      -- use zi to togle folding
o.foldlevelstart = 1      -- some folds closed when start editing (1)
o.foldnestmax = 20        -- limit the folds in the indent and syntax
o.foldminlines = 1        -- limit the folds in the indent and syntax

nnoremap("<leader>z", "za", "Toogle folder under cursor")
nnoremap("<leader>Z", "zA", "Toogle all folders under cursor")

-- Spell
-- :set spell – Turn on spell checking
-- :set nospell – Turn off spell checking
-- z= – Bring up the suggested replacements
-- zg – Good word: Add the word under the cursor to the dictionary
-- zw – Woops! Undo and remove the word from the dictionary
o.spell = true
nnoremap("<leader>n", "]]s<cr>", "Jump to the next misspelled word")
nnoremap("<leader>N", "]]s<cr>", "Jump to the previous misspelled word")

-- Buffer moves
nnoremap("<c-left>", "<c-w><c-h>")
nnoremap("<c-down>", "<c-w><c-j>")
nnoremap("<c-up>", "<c-w><c-k>")
nnoremap("<c-right>", "<c-w><c-l>")

-- Buffer changes
nnoremap("<leader>be", ":bp<cr>", "previous buffer")
nnoremap("<leader>bo", ":bn<cr>", "next buffer")

-- Clipboard
noremap("<leader>y", "\"+y", "system copy")
noremap("<leader>p", "\"+p", "system paste")

-- Unselect
nnoremap("<leader>/", ":noh<cr>", "unselect")

-- Convert existing tabs to spaces
nnoremap("<leader><tab>", ":retab<cr>", "tabs to spaces")

-- Open terminal
nnoremap("<leader>T", ":sp <Bar> :terminal<cr> <bar> i", "open terminal")

-- Aerial --
nnoremap("<leader>a", "<cmd>AerialToggle!<cr>", "toggle aerial")

-- Nvim Tree --
nnoremap("<leader>e", ":NvimTreeFindFile<cr>", "open file tree")
nnoremap("<leader>E", ":NvimTreeToggle<cr>", "toggle file tree")

-- Fzf-lua --
local fzf = require('fzf-lua')
nnoremap("<Leader>sb", fzf.buffers, "open buffers")
nnoremap("<Leader>sf", fzf.files, "find or fd on a path")
nnoremap("<Leader>sF", fzf.oldfiles, "opened files history")
nnoremap("<Leader>st", fzf.tabs, "open tabs")
nnoremap("<Leader>sT", fzf.tags, "search project tags")
nnoremap("<Leader>sa", fzf.grep_project, "search all project lines")
nnoremap("<Leader>ss", fzf.live_grep, "live grep current project")
nnoremap("<Leader>sS", fzf.live_grep_resume, "live grep continue last search")
nnoremap("<Leader>sh", fzf.search_history, "search history")
nnoremap("<Leader>sq", fzf.quickfix, "quickfix list")
nnoremap("<Leader>sQ", fzf.quickfix_stack, "quickfix stack")
nnoremap("<Leader>sl", fzf.loclist, "location list")
nnoremap("<Leader>sL", fzf.loclist_stack, "location stack")
nnoremap("<Leader>so", fzf.jumps, "jumps")
nnoremap("<Leader>sr", fzf.registers, "registers")
nnoremap("<Leader>sk", fzf.keymaps, "keymaps")
nnoremap("<Leader>sc", fzf.changes, "changes")
nnoremap("<Leader>s:", fzf.command_history, "commands history")
nnoremap("<Leader>s/", fzf.search_history, "search history")
nnoremap("<Leader>s'", fzf.marks, "marks")
-- git
-- commits: checkout <cr> | reset mixed <C-r>m | reset soft <C-r>s | reset hard <C-r>h
nnoremap("<Leader>gc", fzf.git_commits, "git commit log (project)")
-- buffer commits: checkout <cr>
nnoremap("<Leader>gb", fzf.git_bcommits, "git commit log (buffer)")
-- branches: checkout <cr> | track <C-t> | rebase <C-r> | create <C-a> | switch <C-s> | delete <C-d> | merge <C-y>
nnoremap("<Leader>gt", fzf.git_branches, "git branches")
nnoremap("<Leader>gs", fzf.git_status, "git status")
nnoremap("<Leader>gS", fzf.git_stash, "git stash")

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
