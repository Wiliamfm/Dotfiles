return {
  "neovim/nvim-lspconfig",
  name = "lspconfig",
  lazy = false,
  dependencies = {
    {
      "williamboman/mason.nvim",
      opts = {
        registries = {

          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        }
      },
      config = true
    },
    {
      "williamboman/mason-lspconfig.nvim",
      opts = {
        ensure_installed = { "lua_ls", "gopls", "dockerls", "ts_ls", "roslyn_ls", "harper_ls" }
      }
    },
  },
  config = function()
    vim.lsp.config("lua_ls")
    vim.lsp.config("pyright")
    vim.lsp.config("biome")
    vim.lsp.config("ts_ls")
    vim.lsp.config("ruff")
    vim.lsp.config("gopls")
    vim.lsp.config("dockerls")
    vim.lsp.config("yamlls")
    vim.lsp.config("harper_ls")
  end,
}
