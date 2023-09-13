vim.cmd.colorscheme "catppuccin"

vim.opt.nu = true
vim.opt.relativenumber = false

-- undotree opt
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
