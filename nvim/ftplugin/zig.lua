-- LSP config for Zig
local core= require("config.core")
core.lsp_config("zig-language-server", {"zls"}, { 'zig.json', 'build.zig', '.git' })
