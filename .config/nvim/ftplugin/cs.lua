-- LSP config for C#
local core = require("config.core")
core.lsp_config("omnisharp",
  { "omnisharp", "-z", "--languageserver", "--hostPID", tostring(vim.fn.getpid()), "DotNet:enablePackageRestore=false", "--encoding=utf8" },
  function(name, path)
    return name:match(".*%.csproj$") or name:match(".*%.sln$")
  end)
