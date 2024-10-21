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
        request = "attach",
        name = "attach - netcoredbg",
        processId = require('dap.utils').pick_process,
      },
    }
  end,
  keys = {
    { '<F5>',       function() require('dap').continue() end,           mode = 'n',                     desc = "DAP: Continue" },
    { '<F10>',      function() require('dap').step_over() end,          desc = "DAP: Step Over" },
    { '<F11>',      function() require('dap').step_into() end,          desc = "DAP: Step Into" },
    { '<F12>',      function() require('dap').step_out() end,           desc = "DAP: Step Out" },
    { '<Leader>b',  function() require('dap').toggle_breakpoint() end,  desc = "DAP: Toggle Breakpoint" },
    { '<Leader>dl', function() require('dap').run_last() end,           desc = "DAP: Run Last" },
    { '<Leader>dh', function() require('dap.ui.widgets').hover() end,   mode = { 'n', 'v' },            desc = "DAP: Hover" },
    { '<Leader>dp', function() require('dap.ui.widgets').preview() end, mode = { 'n', 'v' },            desc = "DAP: Preview" },
  }
}
