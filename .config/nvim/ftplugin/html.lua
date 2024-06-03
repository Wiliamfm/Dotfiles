--LSP for HTML
local lsp = require("config.lsp")

lsp.start_server(
  "html",
  "angular-language-server",
  { "ngserver", "--stdio", "--tsProbeLocations", "./node_modeules" , "--ngProbeLocations", "./node_modules" },
  { ".git", "package.json", "tsconfig.json", "tsconfig.node.json" },
  true
)
