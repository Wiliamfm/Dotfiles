-- LSP config for Zig
local clientId = vim.lsp.start({
  name = 'zig-language-server',
  cmd = { 'zls' },
  root_dir = vim.fs.dirname(vim.fs.find(
    { 'zig.json', 'build.zig', '.git' }, { upward = true }
  )[1]),
  on_attach = function(client, bufnr)
    print('LSP ' .. client.name .. ' attached to bufnr: ' .. bufnr .. ' : ' .. buf_is_attached(0, clientId))
  end,
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
