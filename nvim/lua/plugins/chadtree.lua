local settings = {
    theme = {
      text_colour_set= 'trapdoor'
    }
}

return {
	'ms-jpq/chadtree',
	branch = 'chad',
	build = 'python3 -m chadtree deps',
	keys = {
		{'<leader>e', '<cmd>CHADopen<cr>'}
	},
  config = function()
    --vim.api.nvim_set_var('chadtree_settings', settings)
  end,
}
