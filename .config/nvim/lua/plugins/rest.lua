return {
  "rest-nvim/rest.nvim",
  --enabled = false,
  ft = "http",
  keys= {
    {"<leader>r", ":Rest run<CR>", {desc = "Run a rest request"}}
  }
}
