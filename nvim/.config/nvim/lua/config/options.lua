-- [[ Setting options ]]
-- See `:help vim.o`

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
local use_ssh_clipboard = vim.fn.executable('is-ssh') == 1
  and os.execute('is-ssh') == 0
  and vim.fn.executable('clip') == 1
if use_ssh_clipboard then
  vim.g.ssh_clipboard_copy = true
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = 'clip',
      ['*'] = 'clip',
    },
    paste = {
      ['+'] = 'cat /dev/null',
      ['*'] = 'cat /dev/null',
    },
    cache_enabled = 0,
  }
else
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
end

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.autoread = true

-- [[ Diagnostic Config ]]
-- See :help vim.diagnostic.Opts
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}
