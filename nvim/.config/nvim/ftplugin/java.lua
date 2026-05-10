local data_dir = vim.fn.stdpath 'data'
local workspace_path = data_dir .. '/jdtls-workspace/'
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = workspace_path .. project_name
local mason_packages = data_dir .. '/mason/packages'

local status, jdtls = pcall(require, 'jdtls')
if not status then
  print 'jdtls can not find'
  return
end

local bufnr = vim.api.nvim_get_current_buf()
local bufname = vim.api.nvim_buf_get_name(bufnr)
-- JDTLS expects a real file URI; skip scratch/special Java buffers that would resolve to file://.
if bufname == '' or vim.bo[bufnr].buftype ~= '' then return end

local extendedClientCapabilities = jdtls.extendedClientCapabilities

local bundles = {}
local debug_jar_pattern = mason_packages .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
local debug_jar = vim.fn.glob(debug_jar_pattern)
if debug_jar ~= '' then
  table.insert(bundles, debug_jar)
else
  print 'debug_jar can not find'
end

local config = {
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx2g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. mason_packages .. '/jdtls/lombok.jar',
    '-jar',
    vim.fn.glob(mason_packages .. '/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
    '-configuration',
    mason_packages .. '/jdtls/config_mac',
    '-data',
    workspace_dir,
  },
  root_dir = jdtls.setup.find_root { '.git', 'mvnw', 'gradlew', 'pom.xml' },

  settings = {
    java = {
      home = '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home', -- TODO: Replace this with the absolute path to your main java version (JDTLS requires JDK 21 or higher)
      signatureHelp = { enabled = true },
      extendedClientCapabilities = extendedClientCapabilities,
      configuration = {
        updateBuildConfiguration = 'automatic',
        -- TODO: Update this by adding any runtimes that you need to support your Java projects and removing any that you don't have installed
        runtimes = {
          {
            name = 'JavaSE-17',
            path = '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home',
          },
          {
            name = 'JavaSE-21',
            path = '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
          },
          {
            name = 'JavaSE-25',
            path = '/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home',
          },
        },
      },
      maven = {
        enabled = true,
        downloadSources = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = 'all', -- literals, all, none
        },
      },
      format = {
        enabled = true,
      },
    },
  },

  init_options = {
    bundles = bundles,
  },
}

config['on_attach'] = function()
  local dap_ok, dap = pcall(require, 'dap')
  if not dap_ok then return end

  jdtls.setup_dap { config_overrides = {}, hotcodereplace = 'auto' }
  if dap.providers and dap.providers.configs then dap.providers.configs['jdtls'] = nil end

  local jdtls_dap = require 'jdtls.dap'
  -- Build separate entries for debugging and noDebug runs from the same discovered main classes.
  jdtls_dap.fetch_main_configs({ config_overrides = { noDebug = false } }, function(configurations)
    local dap_configurations = dap.configurations.java or {}

    local function remove_main_class_configs(config)
      for i = #dap_configurations, 1, -1 do
        local existing_config = dap_configurations[i]
        if
          existing_config.type == 'java'
          and existing_config.request == 'launch'
          and existing_config.mainClass == config.mainClass
          and existing_config.projectName == config.projectName
          and existing_config.cwd == config.cwd
        then
          table.remove(dap_configurations, i)
        end
      end
    end

    local function append_config(config) table.insert(dap_configurations, config) end

    for _, config in ipairs(configurations) do
      remove_main_class_configs(config)

      local debug_config = vim.deepcopy(config)
      debug_config.name = debug_config.name:gsub('^Launch ', 'Debug ', 1)
      debug_config.noDebug = false
      append_config(debug_config)

      local run_config = vim.deepcopy(config)
      run_config.name = run_config.name:gsub('^Launch ', 'Run ', 1)
      run_config.noDebug = true
      append_config(run_config)
    end

    dap.configurations.java = dap_configurations
  end)
end

jdtls.start_or_attach(config)

vim.keymap.set('n', '<leader>co', "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = 'Organize Imports' })
vim.keymap.set('n', '<leader>crv', "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = 'Extract Variable' })
vim.keymap.set('v', '<leader>crv', "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", { desc = 'Extract Variable' })
vim.keymap.set('n', '<leader>crc', "<Cmd>lua require('jdtls').extract_constant()<CR>", { desc = 'Extract Constant' })
vim.keymap.set('v', '<leader>crc', "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", { desc = 'Extract Constant' })
vim.keymap.set('v', '<leader>crm', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = 'Extract Method' })
