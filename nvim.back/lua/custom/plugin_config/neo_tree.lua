vim.keymap.set("n", "<leader>e", ":Neotree toggle current reveal_force_cwd<cr>")
vim.keymap.set("n", "<leader>be", ":Neotree toggle show buffers right<cr>")
vim.keymap.set("n", "<leader>gs", ":Neotree toggle float git_status<cr>")

require("neo-tree").setup({
	filesystem = {
		filtered_items = {
			visible = false, -- when true, they will just be displayed differently than normal items
			hide_dotfiles = false,
			hide_gitignored = true,
			hide_hidden = false, -- only works on Windows for hidden files/directories
			hide_by_name = {
				".DS_Store",
				"thumbs.db",
				--"node_modules",
			},
			hide_by_pattern = {
				--"*.meta",
				--"*/src/*/tsconfig.json",
			},
			always_show = { -- remains visible even if other settings would normally hide it
			--".gitignored",
			},
			never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
			--".DS_Store",
			--"thumbs.db",
			},
			never_show_by_pattern = { -- uses glob style patterns
			--".null-ls_*",
			},
		},
	}
})
