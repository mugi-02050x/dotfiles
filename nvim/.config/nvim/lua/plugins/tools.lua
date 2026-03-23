return {
  -- Indent detection
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- Java LSP (loaded via ftplugin/java.lua)
  { 'mfussenegger/nvim-jdtls' },

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
