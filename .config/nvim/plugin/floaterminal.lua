local state = {
  floating = {
    buf = -1,
    win = -1
  },
  lazygit = {
    buf = -1,
    win = -1
  }
}
local create_floating_window = function(buf, opts)
  opts = opts or {}
  -- Get the screen dimensions
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  -- Default width and height as 80% of the screen
  local width = opts.width or math.floor(screen_width * 0.8)
  local height = opts.height or math.floor(screen_height * 0.8)

  -- Calculate the center position
  local row = math.floor((screen_height - height) / 2)
  local col = math.floor((screen_width - width) / 2)

  -- Create the floating window
  local _buf = nil
  if (not vim.api.nvim_buf_is_valid(buf)) then
    _buf = vim.api.nvim_create_buf(false, true)
  else
    _buf = buf
  end
  local win = vim.api.nvim_open_win(_buf, true, { -- Open the window
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded", -- You can customize this border
  })

  -- Optionally, set additional options like highlights, keymaps, etc.
  return { buf = _buf, win = win } -- Return the window handle
end

vim.api.nvim_create_user_command("FloatTerminal", function()
  if (not vim.api.nvim_win_is_valid(state.floating.win)) then
    state.floating = create_floating_window(state.floating.buf)
    if (vim.bo[state.floating.buf].buftype ~= "terminal") then
      vim.cmd.terminal()
      vim.cmd("set relativenumber")
      vim.cmd("startinsert")
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end, {})

vim.api.nvim_create_user_command("FloatLazyGit", function()
  if (not vim.api.nvim_win_is_valid(state.lazygit.win)) then
    state.lazygit = create_floating_window(state.lazygit.buf)
    if (vim.bo[state.lazygit.buf].buftype ~= "terminal") then
      vim.cmd("terminal lazygit")
      vim.cmd("startinsert")
    end
  else
    vim.api.nvim_win_hide(state.lazygit.win)
  end
end, {})
