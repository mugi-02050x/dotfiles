-- Run Python script with <F5>
vim.keymap.set('n', '<F5>', function()
  local file = vim.fn.expand '%'
  vim.cmd 'split'
  vim.cmd('terminal python3 ' .. file)
  vim.cmd 'startinsert'
end, { buffer = true, desc = 'Run Python script' })
