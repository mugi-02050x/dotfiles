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
        eabled = true,
      },
    },
  },

  init_options = {
    bundles = bundles,
  },
}

config['on_attach'] = function(client, bufnr)
  jdtls.setup_dap { hotcodereplace = 'auto' }
  require('jdtls.dap').setup_dap_main_class_configs()
end

jdtls.start_or_attach(config)

vim.keymap.set('n', '<leader>co', "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = 'Organize Imports' })
vim.keymap.set('n', '<leader>crv', "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = 'Extract Variable' })
vim.keymap.set('v', '<leader>crv', "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", { desc = 'Extract Variable' })
vim.keymap.set('n', '<leader>crc', "<Cmd>lua require('jdtls').extract_constant()<CR>", { desc = 'Extract Constant' })
vim.keymap.set('v', '<leader>crc', "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", { desc = 'Extract Constant' })
vim.keymap.set('v', '<leader>crm', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = 'Extract Method' })
