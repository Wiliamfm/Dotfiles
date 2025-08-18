local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 or vim.fn.has("win16") == 1

return {
  "leath-dub/snipe.nvim",
  -- Replaces rabbit.nvim
  enabled = is_windows,
  keys = {
    { "<leader>rr", function() require("snipe").open_buffer_menu() end, desc = "Open Snipe buffer menu" }
  },
  opts = {
    ui = {
      position = "center"
    }
  }
}
