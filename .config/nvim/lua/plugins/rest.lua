return {
  "rest-nvim/rest.nvim",
  enabled = false,
  ft = "http",
  dependencies = { "luarocks.nvim" },
  config = function()
    require("rest-nvim").setup()
  end,
}
