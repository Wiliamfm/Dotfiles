return {
  "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
  lazy = false,            -- REQUIRED: tell lazy.nvim to start this plugin at startup
  dependencies = {
    { "williamboman/mason.nvim", config = true },
    {
      "williamboman/mason-lspconfig.nvim",
      opts = {
        ensure_installed = { "lua_ls", "omnisharp" }
      }
    },
    -- main one
    { "ms-jpq/coq_nvim",         branch = "coq" },

    -- 9000+ Snippets
    { "ms-jpq/coq.artifacts",    branch = "artifacts" },

    -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
    -- Need to **configure separately**
    { 'ms-jpq/coq.thirdparty',   branch = "3p" }
    -- - shell repl
    -- - nvim lua api
    -- - scientific calculator
    -- - comment banner
    -- - etc
  },
  init = function()
    -- Your COQ settings here
    vim.g.coq_settings = {
      auto_start = true, -- if you want to start COQ at startup
      keymap = {
        recommended = false
      }
    }
  end,
  config = function()
    -- Your LSP settings here
    require 'lspconfig'.omnisharp.setup {}
    require 'lspconfig'.lua_ls.setup {}
  end,
}
