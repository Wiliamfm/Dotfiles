local function start_server()
  local root_files = { "go.mod", ".git" }
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
    name = "gopls",
    cmd = { "gopls" },
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
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  desc = "Start gopls",
  callback = start_server
})
