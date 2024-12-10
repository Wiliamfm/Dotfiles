--LSP for HTML
local lsp = require("config.lsp")
local cwd = vim.fn.getcwd() .. "/node_modules"

lsp.start_server(
  "html",
  "angular-language-server",
  { "ngserver", "--stdio", "--tsProbeLocations", cwd, "--ngProbeLocations", cwd },
  { "angular.json" },
  true
)
