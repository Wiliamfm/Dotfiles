-- LSP config for C#
local lsp = require("config.lsp")
lsp.start_server(
  "dockerfile",
  "Docker-LSP",
  { "docker-langserver", "--stdio" },
  "Dockerfile",
  true
)
