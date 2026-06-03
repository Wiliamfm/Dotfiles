return {
  url = "https://codeberg.org/andyg/leap.nvim",
  event = "BufEnter",
  config = function()
    require("leap")
  end,
  keys = {
    {"<leader>s", "<Plug>(leap)", {"n", "x", "o"}, desc = "Leap motion"}
  }
}
