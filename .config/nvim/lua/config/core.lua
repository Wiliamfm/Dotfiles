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

M.lsp_config = function(name, cmd, root_dir)
  local dir = vim.fs.dirname(vim.fs.find(
    root_dir, { upward = true, stop = vim.loop.os_homedir() }
  )[1])
  local clientId = vim.lsp.start({
    name = name,
    cmd = cmd,
    root_dir = dir,
    on_attach = function(client, bufnr)
      print("LSP " .. client.name .. " attached to buffer " .. bufnr)
    end
  })
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.server_capabilities.hoverProvider then
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = args.buf })
    end
    if client.server_capabilities.codeActionProvider then
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = args.buf })
    end
  end,
})

--vim.diagnostic.config({
--  virtual_text = {
--    prefix = '●',
--    source = true
--  },
--})

--vim.diagnostic.open_flaot({
--  max_width= 100,
--  max_height= 200,
--  header= "CUSTOM HEADER BITCH",
--  source= true
--})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    signs = true,
    virtual_text = false,
    float = {
        show_header = true,
        source = 'if_many',
        border = 'rounded',
    },
  }
)

return M
