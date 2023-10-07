vim.g.mapleader = " "

-- Keymaps
vim.keymap.set("n", "<leader>ld", vim.cmd.Ex)
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
vim.keymap.set("n", "<leader>|", ":vsplit<CR>")
vim.keymap.set("n", "<leader>-", ":split<CR>")
vim.keymap.set("n", "<leader>cw", ":close<CR>")
vim.keymap.set("n", "<leader>ts", ":tab split<CR>")
vim.keymap.set("n", "<leader>tc", ":tab close<CR>")
vim.keymap.set("n", "<leader><TAB>", ":tabnext<CR>")
vim.keymap.set("n", "<leader><SHIFT><TAB>", ":tablast<CR>")
