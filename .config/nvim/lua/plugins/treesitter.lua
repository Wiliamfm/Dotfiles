return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      ensure_installed = { "c_sharp", "css", "csv", "dockerfile", "dot", "gitignore", "html", "http", "javascript", "json", "lua", "markdown", "python", "sql", "typescript" },
      sync_install = false,
      highlight = {
        enable = true,
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            vim.notify("skip large file " .. vim.api.nvim_buf_get_name(buf), vim.log.levels.WARN)
            return true
          end
        end,
      },
      indent = { enable = true },
    })
  end
}
