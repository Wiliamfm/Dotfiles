--Global options

vim.g.netrw_bufsettings = 'noma nomod nu rnu nobl nowrap ro'

--Check :options for details

-- Moving around, searching and patterns

vim.opt.incsearch = true

--Displaying text

vim.opt.scrolloff = 999
vim.opt.wrap= true
vim.opt.breakindent= true
vim.opt.number = true
vim.opt.relativenumber = true

-- Syntax, highlighting and spelling

vim.opt.hlsearch = true
vim.opt.termguicolors = true
vim.opt.spell= false
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- Selecting text

vim.opt.clipboard = "unnamedplus" --use unnamedplus to "use" the system clipboard; "" to use default

-- Editing text (12)

vim.opt.formatexpr = "vim.lsp.formatexpr()"

-- Tabs and indenting

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab= true

vim.cmd.colorscheme "catppuccin"

-- undotree opt
--vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
--vim.opt.undofile = true
