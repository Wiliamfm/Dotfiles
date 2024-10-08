local lsp = require("config.lsp")
vim.g.mapleader = " "

-- Keymaps

vim.keymap.set("n", "<leader>e", vim.cmd.Ex)
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
vim.keymap.set("n", "<leader>|", ":vsplit<CR>")
vim.keymap.set("n", "<leader>-", ":split<CR>")
vim.keymap.set("n", "<leader>cw", ":close<CR>")
vim.keymap.set("n", "<tab><tab>", ":tab split<CR>")
vim.keymap.set("n", "<tab>c", ":tab close<CR>")
vim.keymap.set("n", "<leader><TAB>", ":tabnext<CR>")
vim.keymap.set("n", "<leader><S-TAB>", ":tabprevious<CR>")
vim.keymap.set("n", "<leader>t", ":terminal<CR>", { desc = "Open terminal" })
vim.keymap.set("t", "<leader><Esc>", "<c-\\><c-n>", { desc = "Escape terminal", noremap = true })

-- Diagnostics
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open diagnostic" })
vim.keymap.set("n", "<leader>gd", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "<leader>gD", vim.diagnostic.goto_prev, { desc = "Go to prev diagnostic" })

-- LSP
vim.keymap.set("n", "<leader>lr", lsp.lsp_restart)
