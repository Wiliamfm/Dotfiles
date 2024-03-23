-- LSP config for C#
local core = require("config.core")
core.lsp_config("omnisharp",
  { "omnisharp", "-z", "-lsp", "--hostPID", tostring(vim.fn.getpid()), "DotNet:enablePackageRestore=false", "--encoding=utf8" },
  function(name)
    return name:match(".*%.csproj$") or name:match(".*%.sln$")
  end)
