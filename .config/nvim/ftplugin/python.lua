-- LSP config for C#
local lsp = require("config.lsp")
lsp.start_server(
  "python",
  "Pyright",
  { "pyright-langserver", "--stdio" },
  { "pyrightconfig.json", "requirements.txt", "pyproject.toml", ".git" },
  true
)
