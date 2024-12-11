local M = {}

M.format_on_save = false

M.print_msg = function(msg, prefix)
  prefix = prefix or "LSP"
  print(vim.notify(prefix .. ": " .. msg))
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local prefix = "LSP[" .. client.name .. "]"

    --config
    vim.lsp.set_log_level("warn")

    if client.supports_method("textDocument/hover") then
      -- Nvim default keymap.
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = args.buf })
    end

    if client.supports_method("textDocument/formatting") or true then
      local lsp_format = function()
        M.print_msg("Formatting", prefix)
        vim.lsp.buf.format({
          timeout_ms = 5000,
          filter = function(c)
            if (c.name == "tsserver") then
              M.print_msg("tsserver formatting disabled.", prefix)
              return false
            end
            return true
          end
        })
      end

      vim.keymap.set("n", "<leader>ltf", function()
        M.format_on_save = not M.format_on_save
        M.print_msg("Toggling format on save to " .. tostring(M.format_on_save) .. ".", prefix)
        local auId = vim.api.nvim_create_augroup("LspFormatting", {
          clear = true
        })
        if (M.format_on_save) then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = auId,
            buffer = args.buf,
            callback = lsp_format
          })
        end
      end, { buffer = args.buf, nowait = true, noremap = true, desc = "LSP:Toggle Format." })

      vim.keymap.set('n', "<leader>lf", lsp_format,
        { buffer = args.buf, nowait = true, noremap = true, desc = "LSP:Format" })
    end

    if client.supports_method("textDocument/references") then
      vim.keymap.set('n', '<leader>lr', function()
        M.print_msg("Searching references.", prefix)
        vim.lsp.buf.references()
      end, { buffer = args.buf, desc = "LSP:References" })
    end

    if client.supports_method("textDocument/implementation*") then
      vim.keymap.set('n', '<leader>li', function()
        M.print_msg("Searching Implementations.", prefix)
        vim.lsp.buf.implementation()
      end, { buffer = args.buf, noremap = true, nowait = true, desc = "LSP:Implementation" })
    end

    if true or client.supports_method("textDocument/codeAction") then
      vim.keymap.set('n', "<leader>la", function()
        M.print_msg("Code Action.", prefix)
        vim.lsp.buf.code_action()
      end, { buffer = args.buf, nowait = true, desc = "LSP:Code Action" })
    end

    if true or client.supports_method("textDocument/definition") then
      vim.keymap.set('n', '<leader>ld', function()
        M.print_msg("Got to definition.", prefix)
        vim.lsp.buf.definition()
      end, { buffer = args.buf, nowait = true, desc = "LSP:Definition" })
    end

    if true or client.supports_method("textDocument/rename") then
      vim.keymap.set('n', "<leader>lrs", function()
        M.print_msg("Rename.", prefix)
        vim.lsp.buf.rename()
      end, { buffer = args.buf, nowait = true, desc = "LSP:Rename" })
    end

    if true or client.supports_method("textDocument/typeDefinition*") then
      vim.keymap.set('n', "<leader>lD", function()
        M.print_msg("Go to type definition.", prefix)
        vim.lsp.buf.type_definition()
      end, { buffer = args.buf, desc = "LSP:Type Definition" })
    end

    if client.supports_method("textDocument/signatureHelp") then
      vim.keymap.set('n', "<leader>ls", function()
        M.print_msg("Signature Help.", prefix)
        vim.lsp.buf.signature_help()
      end, { buffer = args.buf, desc = "LSP:Signature Help" })
    end

    if client.supports_method("textDocument/inlayHint") then
      M.print_msg("Enable inlay hints.", prefix)
      vim.lsp.inlay_hint.enable(true)
      vim.keymap.set("n", "<leader>.", function()
        local hint = vim.lsp.inlay_hint.get({ bufnr = args.buf })
        for k, v in pairs(hint) do
          vim.inspect(k)
          vim.inspect(v)
        end
        local resp = client.request_sync('inlayHint/resolve', hint.inlay_hint, 100, 0)
        print(vim.inspect(hint))
        print(vim.inspect(resp, prefix))
      end, { buffer = args.buf, nowait = true, desc = "LSP: Trigger completion" })
    end

    if client.supports_method("textDocument/completion") then
      M.print_msg("Enable completion." .. vim.version().minor)
      if (vim.version().minor < 11) then
        vim.keymap.set("i", "<CTR>.", vim.lsp.buf.completion,
          { buffer = args.buf, nowait = true, desc = "LSP: Trigger completion" })
      else
        vim.lsp.completion.enable(true, client.id, args.buf)
        vim.keymap.set("i", "<c-.>", function()
            M.print_msg("Trigger completion.", prefix)
            vim.lsp.completion.trigger()
          end,
          { buffer = args.buf, nowait = true, desc = "LSP: Trigger completion" })
      end
    end

    --TODO: Make this keymap open lsp log file in a new tab | window.
    vim.keymap.set('n', "<leader>ll", function() M.print_msg(vim.lsp.get_log_path(), prefix) end,
      { buffer = args.buf, nowait = true, desc = "LSP:Log Path." })
    vim.keymap.set('n', "<leader>te", function() vim.lsp.codelens.run() end,
      { buffer = args.buf, nowait = true, desc = "LSP:Log Path" })
    vim.keymap.set('n', "<leader>tt", function() vim.lsp.codelens.get(args.buf) end,
      { buffer = args.buf, nowait = true, desc = "LSP:Log Path" })
  end,
})
