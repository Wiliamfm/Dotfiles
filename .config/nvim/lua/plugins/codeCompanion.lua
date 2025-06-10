return {
  "olimorris/codecompanion.nvim",
  opts = {
    adapters = {
      deepseek = function()
        return require("codecompanion.adapters").extend("deepseek", {
          env = {
            api_key = "sk-6bc83132d22a44a7aa11a5eded2fb4a3"
          }
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "ollama"
      },
      inline = {
        adapter = "ollama"
      }
    }
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
}
