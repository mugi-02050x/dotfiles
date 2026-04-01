-- [[ Basic Keymaps ]]
-- See `:help vim.keymap.set()`

-- swap colon and semicolon
vim.keymap.set('n', ';', ':')
vim.keymap.set('n', ':', ';')

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Open diagnostic quickfix list
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Exit insert mode
vim.keymap.set('i', 'jj', '<ESC>', { desc = 'Exit normal mode' })

