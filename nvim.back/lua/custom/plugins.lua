local plugins = {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
	},
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.1',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v2.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		}
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = function()
			("nvim-treesitter.install").update({ with_sync = true })
		end,
	},
	{
		'nvim-lualine/lualine.nvim',
		dependencies = {
			{ 'dokwork/lualine-ex' },
			{ 'nvim-lua/plenary.nvim' },
			{ 'nvim-tree/nvim-web-devicons', opt = true }
		},
	},
	{
		"mbbill/undotree"
	},
	{
		"tpope/vim-fugitive"
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v2.x',
		dependencies = {
			-- LSP Support
			{ 'neovim/nvim-lspconfig' }, -- Required
			{                         -- Optional
				'williamboman/mason.nvim',
				build = function()
					pcall(vim.cmd, 'MasonUpdate')
				end,
			},
			{ 'williamboman/mason-lspconfig.nvim' }, -- Optional

			-- Autocompletion
			{ 'hrsh7th/nvim-cmp' },  -- Required
			{ 'hrsh7th/cmp-nvim-lsp' }, -- Required
			--{'rafamadriz/friendly-snippets'},
			{ 'L3MON4D3/LuaSnip' },  -- Required
		}
	},
	{
		'jiangmiao/auto-pairs'
	},
	{
		'Hoffs/omnisharp-extended-lsp.nvim'
	},
	{
		'rest-nvim/rest.nvim',
		dependencies = {
			"nvim-lua/plenary.nvim"
		}
	},
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {}
	},
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {}
	},
}

return plugins
