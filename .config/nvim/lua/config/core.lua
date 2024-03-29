local M = {}

-- re map netrw keys.
vim.api.nvim_create_autocmd('filetype', {
  pattern = 'netrw',
  desc = 'Better mappings for netrw',
  callback = function()
    local bind = function(lhs, rhs)
      vim.keymap.set('n', lhs, rhs, { remap = true, buffer = true })
    end
    -- edit new file
    bind('n', '%')
    -- rename file
    bind('r', 'R')
  end
})

vim.diagnostic.config({
  float = {
    border = 'rounded',
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.HINT] = '⚑',
      [vim.diagnostic.severity.INFO] = '»',
    },
  },
})

M.lsp_config = function(name, cmd, root_dir)
  local dir = vim.fs.dirname(vim.fs.find(
    root_dir,
    { upward = true, stop = vim.loop.os_homedir(), path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))}
  )[1])
  local clientId = vim.lsp.start({
    name = name,
    cmd = cmd,
    root_dir = dir,
    on_attach = function(client, bufnr)
      print("LSP " .. client.name .. " attached to buffer " .. bufnr)
    end
  })
  if (clientId ~= nil) then
    print("lsp client id: " .. clientId .. " lsp dir: " .. dir)
  end
end

return M
