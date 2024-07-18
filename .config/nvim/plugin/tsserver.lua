local lsp = require("config.lsp")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "html" },
  desc = "Start tsserver",
  callback = function()
    lsp.start_server(
      "",
      "tsserver",
      { "typescript-language-server", "--stdio" },
      function(name)
        return name:match("package.json") or name:match("tsconfig.json") or name:match("angular.json")
      end,
      true
    )
  end
})
