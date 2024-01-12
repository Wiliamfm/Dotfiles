-- LSP config for Lua
local clientId= vim.lsp.start({
  name = 'lua-language-server',
  cmd = {'lua-language-server'},
  root_dir = vim.fs.dirname(vim.fs.find(
    {'init.lua'}, { upward = true}
  )[1])
})

vim.lsp.buf_attach_client(0, clientId)

print('Client ' ..clientId.. ' Attached to current buffer')
