return {
  "j-morano/buffer_manager.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    order_buffers = "lastused",
    focus_alternate_buffer = true
  },
  keys = {
    { "<leader>rr", ":lua require('buffer_manager.ui').toggle_quick_menu()<cr>", desc = "Toggle Buffer Manager" },
  }
}
