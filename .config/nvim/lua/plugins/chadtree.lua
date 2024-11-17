local settings = {
    theme = {
      text_colour_set= 'trapdoor'
    }
}

local chadtree = {
	'ms-jpq/chadtree',
  enabled = false,
	branch = 'chad',
	build = 'python3 -m chadtree deps',
	keys = {
		{'<leader><S-e>', '<cmd>CHADopen<cr>'}
	},
  config = function()
    --vim.api.nvim_set_var('chadtree_settings', settings)
  end,
}

return chadtree
