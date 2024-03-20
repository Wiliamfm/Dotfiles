vim.g.mapleader = " "

-- Keymaps

vim.keymap.set("n", "<leader>e", vim.cmd.Ex)
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
vim.keymap.set("n", "<leader>|", ":vsplit<CR>")
vim.keymap.set("n", "<leader>-", ":split<CR>")
vim.keymap.set("n", "<leader>cw", ":close<CR>")
vim.keymap.set("n", "<leader>t", ":tab split<CR>")
vim.keymap.set("n", "<leader>tc", ":tab close<CR>")
vim.keymap.set("n", "<leader><TAB>", ":tabnext<CR>")
vim.keymap.set("n", "<leader><S-TAB>", ":tabprevious<CR>")
