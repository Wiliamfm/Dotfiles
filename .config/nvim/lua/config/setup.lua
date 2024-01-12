--Check :options for details
-- Moving around, searching and patterns

vim.opt.incsearch = true

--Displayin text

vim.opt.scrolloff = 999
vim.opt.wrap= true
vim.opt.breakindent= true
vim.opt.number = true
vim.opt.relativenumber = false

-- Syntax, highlighting and spelling

vim.opt.hlsearch = true
vim.opt.termguicolors = true
vim.opt.spell= false

-- Selecting text

vim.opt.clipboard = "unnamedplus" --use unnamedplus to "use" the system clipboard; "" to use default

-- Tabs and indenting

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab= true

vim.cmd.colorscheme "catppuccin"

-- undotree opt
--vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
--vim.opt.undofile = true
