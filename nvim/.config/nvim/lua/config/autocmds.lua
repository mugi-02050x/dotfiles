-- [[ Basic Autocommands ]]
-- See `:help lua-guide-autocommands`

-- Reload file when changed outside Neovim
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  desc = 'Auto reload file when changed outside Neovim',
  group = vim.api.nvim_create_augroup('auto-reload', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd 'checktime'
    end
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Copy SSH yanks to the client clipboard',
  group = vim.api.nvim_create_augroup('ssh-clipboard-yank', { clear = true }),
  callback = function()
    if not vim.g.ssh_clipboard_copy then return end

    local event = vim.v.event
    if event.operator ~= 'y' or event.regname == '+' or event.regname == '*' then return end

    local lines = event.regcontents
    if type(lines) ~= 'table' or #lines == 0 then return end

    local text = table.concat(lines, '\n')
    if event.regtype == 'V' then text = text .. '\n' end

    local job = vim.fn.jobstart({ 'clip' }, { stdin = 'pipe' })
    if job <= 0 then return end

    vim.fn.chansend(job, text)
    vim.fn.chanclose(job, 'stdin')
  end,
})
