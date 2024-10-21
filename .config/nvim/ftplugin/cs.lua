-- LSP config for C#
local lsp = require("config.lsp")
lsp.start_server(
  "cs",
  "OmniSharp",
  { "omnisharp", "-z", "-lsp", "--hostPID", tostring(vim.fn.getpid()), "DotNet:enablePackageRestore=false", "--encoding=utf8" },
  function(name)
    return name:match(".*%.sln$") --or name:match(".*%.csproj$")
  end,
  true
)
