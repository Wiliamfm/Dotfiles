-- LSP config for CSS
local lsp = require("config.lsp")
lsp.start_server(
  "css",
  "css-lsp",
  { "vscode-css-language-server", "--stdio" },
  { "package.json", "tsconfig.json", ".git" },
  true
)
