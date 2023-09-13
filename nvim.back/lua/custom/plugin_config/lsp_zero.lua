local lsp = require('lsp-zero').preset({})

-- CMP configuration
-- Make sure you setup `cmp` after lsp-zero

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

require('luasnip.loaders.from_vscode').lazy_load()
require 'luasnip'.filetype_extend("python", { "django" })

cmp.setup({
	sources = {
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' },
	},
	mapping = {
		['<C-f>'] = cmp_action.luasnip_jump_forward(),
		['<C-b>'] = cmp_action.luasnip_jump_backward(),
		['<Tab>'] = cmp_action.luasnip_supertab(),
		['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
		['<CR>'] = cmp.mapping.confirm({ select = true }),
	}
})

local lsp_config = require("lspconfig")

lsp_config.lua_ls.setup(lsp.nvim_lua_ls())

lsp_config['omnisharp'].setup {
	handlers = {
		["textDocument/definition"] = require('omnisharp_extended').handler,
	},
	cmd = { 'omnisharp' },
	on_init = function(client)
		client.server_capabilities.semanticTokensProvider = nil
	end
}

lsp_config['tailwindcss'].setup {}


lsp.on_attach(function(client, bufnr)
	lsp.default_keymaps({ buffer = bufnr })
	lsp.buffer_autoformat()
end)

lsp.ensure_installed({
	'rust_analyzer',
	'tsserver',
	'eslint',
	'lua_ls'
})

lsp.setup()
