local function start_server()
  local root_files = { "package.json", "tsconfig.json", "jsconfig.json", ".git" }
  local paths = vim.fs.find(
    root_files,
    { upward = true, stop = vim.loop.os_homedir(), path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) }
  )
  local dir = vim.fs.dirname(paths[1])

  if dir == nil then
    print("Could not find root directory\n" .. paths[1])
    return
  end

  local clientId = vim.lsp.start({
    name = "tsserver",
    cmd = { "typescript-language-server", "--stdio" },
    root_dir = root_dir,
    on_attach = function(client, bufnr)
      print("LSP " .. client.name .. " attached to buffer " .. bufnr)
    end
  })
  if (clientId ~= nil) then
    print("lsp client id: " .. clientId .. " lsp dir: " .. dir)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  desc = "Start tsserver",
  callback = start_server
})
