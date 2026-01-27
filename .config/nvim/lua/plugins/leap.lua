return {
  url = "https://codeberg.org/andyg/leap.nvim",
  event = "BufEnter",
  config = function()
    require("leap").create_default_mappings()
  end,
}
