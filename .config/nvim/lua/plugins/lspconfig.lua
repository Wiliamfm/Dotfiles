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
        ensure_installed = { "lua_ls", "gopls", "dockerls", "ts_ls", "harper_ls", "ty" }
      }
    },
  }
}
