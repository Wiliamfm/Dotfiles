require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = "|",
    section_separators = { left = '', right = '' },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
		lualine_c = {
			-- https://github.com/dokwork/lualine-ex
			{
				'ex.lsp.single',
				lsp_is_off = "NO LSP LOADED",
			}
		},
    lualine_x = {
			{
				'filename',
				path = 1,
			},
			'encoding',
			'filetype'
		},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    --lualine_c = {'filename'},
    --lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
