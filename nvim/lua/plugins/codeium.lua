return {
  'Exafunction/codeium.vim',
  event = 'BufEnter',
	keys = {
    {'<leader><CR>', 'function() return vim.fn["codeium#Accept"]() end', { expr = true, silent = true }},
    {'<c-;>', 'function() return vim.fn["codeium#CycleCompletions"](1) end', { expr = true, silent = true }},
    {'<c-,>', 'function() return vim.fn["codeium#CycleCompletions"](-1) end', { expr = true, silent = true }},
    {'<c-x>', 'function() return vim.fn["codeium#Clear"]() end', { expr = true, silent = true }},
	},
}
