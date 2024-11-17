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
}
