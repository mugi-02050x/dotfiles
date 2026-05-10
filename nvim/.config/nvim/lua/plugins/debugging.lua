return {
  'rcarriga/nvim-dap-ui',
  event = 'VeryLazy',
  dependencies = {
    'mfussenegger/nvim-dap',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-telescope/telescope-dap.nvim',
  },
  opts = {
    controls = {
      element = 'repl',
      enabled = false,
      icons = {
        disconnect = '',
        pause = '',
        play = '',
        run_last = '',
        step_back = '',
        step_into = '',
        step_out = '',
        step_over = '',
        terminate = '',
      },
    },
    element_mappings = {},
    expand_lines = true,
    floating = {
      border = 'single',
      mappings = {
        close = { 'q', '<Esc>' },
      },
    },
    force_buffers = true,
    icons = {
      collapsed = '',
      current_frame = '',
      expanded = '',
    },
    layouts = {
      {
        elements = {
          { id = 'scopes', size = 0.50 },
          { id = 'stacks', size = 0.30 },
          { id = 'watches', size = 0.10 },
          { id = 'breakpoints', size = 0.10 },
        },
        size = 40,
        position = 'left',
      },
      {
        elements = { 'repl', 'console' },
        size = 10,
        position = 'bottom',
      },
    },
    mappings = {
      edit = 'e',
      expand = { '<CR>', '<2-LeftMouse>' },
      open = 'o',
      remove = 'd',
      repl = 'r',
      toggle = 't',
    },
    render = {
      indent = 1,
      max_value_lines = 100,
    },
  },
  config = function(_, opts)
    local dap = require 'dap'
    require('dapui').setup(opts)
    local dapui_terminal_win_cmd = dap.defaults.fallback.terminal_win_cmd
    dap.defaults.fallback.terminal_win_cmd = function(config)
      if config.type == 'java' and config.noDebug then
        vim.cmd 'botright 15new'
        return vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
      end
      return dapui_terminal_win_cmd(config)
    end
    dap.defaults.fallback.focus_terminal = true

    local function prune_stopped_dap_terminals()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name:match '%[dap%-terminal%]' and vim.bo[bufnr].buftype == 'terminal' then
          local job_id = vim.b[bufnr].terminal_job_id
          local running = false
          if job_id then
            local ok, result = pcall(vim.fn.jobwait, { job_id }, 0)
            running = ok and result[1] == -1
          end
          if not running then vim.api.nvim_buf_delete(bufnr, { force = true }) end
        end
      end
    end

    dap.listeners.on_config['dap_prune_stopped_terminals'] = function(config)
      if config.type == 'java' and config.noDebug then prune_stopped_dap_terminals() end
      return config
    end

    -- Breakpoint signs
    vim.api.nvim_set_hl(0, 'DapStoppedHl', { fg = '#98BB6C', bg = '#2A2A2A', bold = true })
    vim.api.nvim_set_hl(0, 'DapStoppedLineHl', { bg = '#204028', bold = true })
    vim.fn.sign_define('DapStopped', { text = '>', texthl = 'DapStoppedHl', linehl = 'DapStoppedLineHl', numhl = '' })
    vim.fn.sign_define('DapBreakpoint', { text = 'B', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = 'C', texthl = 'DiagnosticSignWarn', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = 'R', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = 'L', texthl = 'DiagnosticSignInfo', linehl = '', numhl = '' })

    -- Keymaps
    vim.keymap.set('n', '<leader>bb', "<cmd>lua require'dap'.toggle_breakpoint()<cr>", { desc = 'Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>bc', "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", { desc = 'Conditional Breakpoint' })
    vim.keymap.set('n', '<leader>bl', "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>", { desc = 'Logpoint' })
    vim.keymap.set('n', '<leader>br', "<cmd>lua require'dap'.clear_breakpoints()<cr>", { desc = 'Clear Breakpoints' })
    vim.keymap.set('n', '<leader>ba', '<cmd>Telescope dap list_breakpoints<cr>', { desc = 'List Breakpoints' })
    vim.keymap.set('n', '<leader>dc', "<cmd>lua require'dap'.continue()<cr>", { desc = 'Debug Continue' })
    vim.keymap.set('n', '<leader>dj', "<cmd>lua require'dap'.step_over()<cr>", { desc = 'Debug Step Over' })
    vim.keymap.set('n', '<leader>dk', "<cmd>lua require'dap'.step_into()<cr>", { desc = 'Debug Step Into' })
    vim.keymap.set('n', '<leader>do', "<cmd>lua require'dap'.step_out()<cr>", { desc = 'Debug Step Out' })
    vim.keymap.set('n', '<F5>', "<cmd>lua require'dap'.step_into()<cr>", { desc = 'Debug Step Into' })
    vim.keymap.set('n', '<F6>', "<cmd>lua require'dap'.step_over()<cr>", { desc = 'Debug Step Over' })
    vim.keymap.set('n', '<F7>', "<cmd>lua require'dap'.step_out()<cr>", { desc = 'Debug Step Out' })
    vim.keymap.set('n', '<F8>', "<cmd>lua require'dap'.continue()<cr>", { desc = 'Debug Continue' })
    vim.keymap.set('n', '<F11>', "<cmd>lua require'dap'.run_last()<cr>", { desc = 'Debug Run Last' })
    vim.keymap.set('n', '<leader>dd', function()
      require('dap').disconnect()
      require('dapui').close()
    end, { desc = 'Debug Disconnect' })
    vim.keymap.set('n', '<leader>dt', function()
      require('dap').terminate()
      require('dapui').close()
    end, { desc = 'Debug Terminate' })
    vim.keymap.set('n', '<leader>dr', "<cmd>lua require'dap'.repl.toggle()<cr>", { desc = 'Debug REPL' })
    vim.keymap.set('n', '<leader>dl', "<cmd>lua require'dap'.run_last()<cr>", { desc = 'Debug Run Last' })
    vim.keymap.set('n', '<leader>di', function() require('dap.ui.widgets').hover() end, { desc = 'Debug Inspect' })
    vim.keymap.set('n', '<leader>d?', function()
      local widgets = require 'dap.ui.widgets'
      widgets.centered_float(widgets.scopes)
    end, { desc = 'Debug Scopes' })
    vim.keymap.set('n', '<leader>df', '<cmd>Telescope dap frames<cr>', { desc = 'Debug Frames' })
    vim.keymap.set('n', '<leader>dh', '<cmd>Telescope dap commands<cr>', { desc = 'Debug Commands' })
    vim.keymap.set('n', '<leader>de', function() require('telescope.builtin').diagnostics { default_text = ':E:' } end, { desc = 'Error Diagnostics' })

    dap.listeners.after.event_initialized['dapui_config'] = function(session)
      if session.config.noDebug then
        require('dapui').close()
        return
      end
      vim.cmd 'Neotree close'
      require('dapui').open()
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
      -- Commented to prevent DAP UI from closing when unit tests finish
      -- require('dapui').close()
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
      -- Commented to prevent DAP UI from closing when unit tests finish
      -- require('dapui').close()
    end

    -- Java attach configuration. Main-class launch configs are generated by ftplugin/java.lua.
    local java_configurations = dap.configurations.java or {}
    for i = #java_configurations, 1, -1 do
      if java_configurations[i].name == 'Debug Attach (5005)' then table.remove(java_configurations, i) end
    end
    table.insert(java_configurations, {
      name = 'Debug Attach (5005)',
      type = 'java',
      request = 'attach',
      hostName = '127.0.0.1',
      port = 5005,
    })
    dap.configurations.java = java_configurations
  end,
}
