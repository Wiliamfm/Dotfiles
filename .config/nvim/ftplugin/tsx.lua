-- LSP config for TypeScript
local core = require("config.core")
core.lsp_config("tsserver",
  { "typescript-language-server", "--stdio" },
  { ".git", "package.json", "tsconfig.json", "tsconfig.node.json" })
