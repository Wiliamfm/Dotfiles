return {
  "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
  name = "lspconfig",
  lazy = false,            -- REQUIRED: tell lazy.nvim to start this plugin at startup
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
        ensure_installed = { "lua_ls", "gopls", "dockerls", "ts_ls", "roslyn_ls" }
      }
    },
    -- main one
    { "ms-jpq/coq_nvim",      branch = "coq" },

    -- 9000+ Snippets
    { "ms-jpq/coq.artifacts", branch = "artifacts" },

    -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
    -- Need to **configure separately**
    {
      'ms-jpq/coq.thirdparty',
      branch = "3p",
      init = function()
        -- Can't both show ghost texts though
        --vim.g.codeium_render = false
      end,
      config = function()
        -- TODO: Check this, it's not working.
        require('coq_3p') {
          { src = "builtin/css",    short_name = "nCss" },
          { src = "builtin/html",   short_name = "nHtml" },
          { src = "builtin/js",     short_name = "nJs" },
          { src = "builtin/syntax", short_name = "nSyntax" },
          --{ src = "repl", sh = "zsh", shell = { p = "perl", n = "node" }, max_lines = 99, deadline = 500, unsafe = { "rm", "poweroff", "mv" } } -- TODO: check this
          { src = "nvimlua",        short_name = "nLUA",   conf_only = true },
          { src = "cow",            trigger = "!cow" },
          { src = "figlet",         short_name = "BIG",    trigger = "!big" },
          { src = "codeium",        short_name = "COD" }
        }
      end
    }
  },
  init = function()
    -- Your COQ settings here
    vim.g.coq_settings = {
      auto_start = true, -- if you want to start COQ at startup
      keymap = {
        recommended = false
      },
      completion = {
        skip_after = { "{", "}", "(", ")" }
      },
      clients = {
        lsp = {
          short_name = "LSP",
          weight_adjust = 1.5
        }
      }
    }
  end,
  config = function()
    -- Your LSP settings here
    local coq_ok, coq = pcall(require, "coq")
    if not coq_ok then
      print("coq not found")
      return
    end
    vim.lsp.config("lua_ls", coq.lsp_ensure_capabilities())
    vim.lsp.config("pyright", coq.lsp_ensure_capabilities())
    vim.lsp.config("biome", coq.lsp_ensure_capabilities())
    vim.lsp.config("ts_ls", coq.lsp_ensure_capabilities())
    vim.lsp.config("ruff", coq.lsp_ensure_capabilities())
    vim.lsp.config("gopls", coq.lsp_ensure_capabilities())
    vim.lsp.config("dockerls", coq.lsp_ensure_capabilities())
    vim.lsp.config("yamlls", coq.lsp_ensure_capabilities())
  end,
}
