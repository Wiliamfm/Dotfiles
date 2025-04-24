return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      ensure_installed = { "c_sharp", "css", "csv", "dockerfile", "dot", "gitignore", "html", "http", "javascript", "json", "lua", "markdown", "python", "sql", "typescript" },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
