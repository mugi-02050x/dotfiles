return {
  -- Indent detection
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- Seamless navigation between tmux panes and vim windows
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<cr>' },
      { '<C-j>', '<cmd>TmuxNavigateDown<cr>' },
      { '<C-k>', '<cmd>TmuxNavigateUp<cr>' },
      { '<C-l>', '<cmd>TmuxNavigateRight<cr>' },
      { '<C-\\>', '<cmd>TmuxNavigatePrevious<cr>' },
    },
  },

  -- Java LSP (loaded via ftplugin/java.lua)
  { 'mfussenegger/nvim-jdtls' },

  -- Markdown preview in browser
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && npm install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    ft = { 'markdown' },
    keys = {
      {
        '<leader>mp',
        '<cmd>MarkdownPreviewToggle<cr>',
        ft = 'markdown',
        desc = 'Markdown Preview Toggle',
      },
    },
  },

  -- Live Server for HTML/CSS/JS development
  {
    'barrett-ruth/live-server.nvim',
    build = 'npm install -g live-server',
    cmd = { 'LiveServerStart', 'LiveServerStop' },
    init = function() vim.g.live_server = {} end,
    keys = {
      {
        '<leader>ls',
        function()
          local dir = vim.fn.input('Root dir: ', vim.fn.expand '%:p:h', 'dir')
          if dir ~= '' then require('live-server').start(dir) end
        end,
        desc = 'Start Live Server',
      },
      {
        '<leader>lx',
        '<cmd>LiveServerStop<cr>',
        desc = 'Stop Live Server',
      },
    },
  },
}
