vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = 'rounded' }
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  { border = 'rounded' }
)

local get_on_list_text = function(items)
  local text = {}
  for key, value in ipairs(items) do
    --print(key)
    if (key == "text") then
      --print(value)
      table.insert(text, value)
    end
  end
  return text
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    local function on_list(options)
      for key, value in ipairs(options) do
        print("Key: " .. key .. " Value: " .. value)
      end
      local buf = vim.api.nvim_create_buf(false, false)
      --      vim.api.nvim_buf_set_lines(buf, 0, -1, false, get_on_list_text(options.items))
      --      vim.api.nvim_open_win(buf, true, {
      --        relative = 'win',
      --        row = 5,
      --        col = 5,
      --        width = 50,
      --        height = 10,
      --        border = 'rounded',
      --        title = options.title,
      --        title_pos = 'center',
      --      })
    end

    if client.server_capabilities.hoverProvider then
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = args.buf })
    end
    if client.server_capabilities.documentFormattingProvider then
      vim.keymap.set('n', '<leader>cf', function()
        vim.lsp.buf.format({
          filter = function(c)
            if (c.name == "tsserver") then
              print("tsserver formatting disabled")
              return false
            end
            return c.name ~= "tsserver"
          end
        })
      end, { buffer = args.buf, desc = "LSP:Format" })
    end
    if client.server_capabilities.referencesProvider then
      vim.keymap.set('n', 'gr', function()
        vim.lsp.buf.references(nil, { on_list = on_list })
      end, { buffer = args.buf, desc = "LSP:References" })
    end
    if client.server_capabilities.implementationProvider then
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = args.buf, desc = "LSP:Implementation" })
    end
    if client.server_capabilities.codeActionProvider then
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = args.buf, desc = "LSP:Code Action" })
    end
    if client.server_capabilities.definitionProvider then
      vim.keymap.set('n', 'gd', function()
        print("LSP:Definition")
        vim.lsp.buf.definition { on_list = on_list }
      end, { buffer = args.buf, desc = "LSP:Definition" })
    end
    if client.server_capabilities.renameProvider then
      vim.keymap.set('n', '<leader>cr', function()
        vim.lsp.buf.rename()
      end, { buffer = args.buf, desc = "LSP:Rename" })
    end
    if client.server_capabilities.typeDefinitionProvider then
      vim.keymap.set('n', 'gD', function()
        vim.lsp.buf.type_definition()
      end, { buffer = args.buf, desc = "LSP:Type Definition" })
    end
    if client.server_capabilities.signatureHelpProvider then
      vim.keymap.set('n', '<leader>K', function()
        vim.lsp.buf.signature_help()
      end, { buffer = args.buf, desc = "LSP:Signature Help" })
    end
  end,
})
