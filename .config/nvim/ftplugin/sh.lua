-- LSP config for Bash
local clientId = vim.lsp.start({
  name = 'bash-language-server',
  cmd = { 'bash-language-server', 'start' },
  root_dir = vim.fs.dirname(vim.fs.find(
    { '*.sh' }, { upward = true }
  )[1]),
})

vim.lsp.buf_attach_client(0, clientId)

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.server_capabilities.hoverProvider then
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = args.buf })
    end
  end,
})
