return {
  'Exafunction/codeium.vim',
  event = 'BufEnter',
  init = function()
    vim.g.codeium_disable_bindings = 1
    --vim.api.nvim_call_function("codeium#GetStatusString", {}) -- Does not works!
  end,
  keys = {
    { "<c-i>", function() return vim.fn['codeium#Accept']() end,             mode = "i", expr = true, silent = true },
    { "<c-;>",  function() return vim.fn["codeium#CycleCompletions"](1) end,  mode = "i", expr = true, silent = true },
    { "<c-,>",  function() return vim.fn["codeium#CycleCompletions"](-1) end, mode = "i", expr = true, silent = true },
    { "<c-x>",  function() return vim.fn["codeium#Clear"]() end,              mode = "i", expr = true, silent = true },
  },
}
--TODO: Check docs to enable this plugin instead.
--return {
--  'Exafunction/codeium.nvim',
--  dependencies = {
--    "nvim-lua/plenary.nvim"
--  },
--  event = 'BufEnter',
--  opts = {
--    virtual_text = {
--      map_keys = false,
--      key_bindings = {
--        accept = "<c-i>"
--      }
--    }
--  },
--}
