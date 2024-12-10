local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 or vim.fn.has("win16") == 1

local opts = {
  default_keys = {
    close = { "<Esc>", "q", "<leader>" },
    select = { "<CR>" },
    open = { "<leader>rr" },
    file_add = { "a" },
    file_del = { "<Del>" },
    group = { "A" },
    group_up = { "-" },
  },
}

return {
  "voxelprismatic/rabbit.nvim",
  config = function()
      require("rabbit").setup( opts )
  end,
  --Windows is not supported.
  enabled = not is_windows
}
