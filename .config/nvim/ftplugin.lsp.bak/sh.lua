-- LSP config for Bash
local core= require("config.core")
core.lsp_config("bash-language-server", { 'bash-language-server', 'start' }, { '*.sh' })
