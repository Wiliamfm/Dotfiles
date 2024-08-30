return {
  'mfussenegger/nvim-dap',
  config = function()
    local dap = require('dap')
    dap.adapters.coreclr = {
      type = 'executable',
      command = 'netcoredbg',
      args = { '--interpreter=vscode' }
    }
    dap.configurations.cs = {
      {
        type = "coreclr",
        request = "launch",
        name = "launch - netcoredbg",
        program = function()
          local dotnet_version = vim.fn.input('Dotnet version(default: 8.0):\n', '8.0')
          local parent_dir = vim.fn.input(vim.fn.getcwd(), '', 'file')
          local path = vim.fn.input('Path to dll:\n', vim.fn.getcwd() .. parent_dir .. '/bin/Debug/net' .. dotnet_version,
            'file')
          local file_exist = vim.fn.filereadable(path)
          if file_exist ~= 0 then
            return path
          else
            vim.print('File does not exist: ' .. path)
            return ''
          end
        end,
      },
    }
  end,
  keys = {
    { '<F5>',      function() require('dap').continue() end,          mode = 'n',                     desc = "DAP: Continue" },
    { '<F10>',     function() require('dap').step_over() end,         desc = "DAP: Step Over" },
    { '<F11>',     function() require('dap').step_into() end,         desc = "DAP: Step Into" },
    { '<F12>',     function() require('dap').step_out() end,          desc = "DAP: Step Out" },
    { '<Leader>b', function() require('dap').toggle_breakpoint() end, desc = "DAP: Toggle Breakpoint" },
  }
}
