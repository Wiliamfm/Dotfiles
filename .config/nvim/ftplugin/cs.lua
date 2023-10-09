-- LSP config for C#

local name = 'omnisharp'

local clientId = vim.lsp.start({
  name = name,
  cmd = { 'omnisharp', '-z', '--language-server', '--hostPID', tostring(vim.fn.getpid()),
    'DotNet:enablePackageRestore=false' },
  root_dir = vim.fs.dirname(vim.fs.find(
    function(name, _)
      return name:match('.+%.sln$') or name:match('.+%.csproj$')
    end,
    { upward = true })[1])
})

vim.lsp.buf_attach_client(0, clientId)

print(string.format('LSP Server {%s}:{%s} started', clientId, name))
