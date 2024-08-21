-- LSP config for Lua
local lsp = require("config.lsp")
lsp.start_server(
  "lua",
  "lua_ls",
  { "lua-language-server"},
  "init.lua",
  true
)
