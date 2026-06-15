return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'leoluz/nvim-dap-go',
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-neotest/nvim-nio',
      'williamboman/mason.nvim',
      {
        'mfussenegger/nvim-dap-python',
        ft = 'python',
        -- config = function()
        -- Use this if uv not working
        --   local path = '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python3'
        --   require('dap-python').setup(path)
        -- end,
      },
    },
    config = function()
      local dap = require('dap')
      local ui = require('dapui')

      require('dapui').setup()
      require('dap-go').setup({
        -- Additional dap configurations can be added.
        -- dap_configurations accepts a list of tables where each entry
        -- represents a dap configuration. For more details do:
        -- :help dap-configuration
        dap_configurations = {
          {
            -- Must be "go" or it will be ignored by the plugin
            type = 'go',
            name = 'Panomics Webserver',
            outputMode = 'remote',
            request = 'launch',
            program = '${workspaceFolder}',
            -- program = '${file}',
            buildFlags = { '-tags=dev' },
          },
          {
            -- Must be "go" or it will be ignored by the plugin
            type = 'go',
            name = 'Nexus',
            outputMode = 'remote',
            request = 'launch',
            program = '${workspaceFolder}/cmd/nexus',
            -- program = '${file}',
            -- buildFlags = { '-tags=dev' },
          },
        },
        -- delve configurations
        -- delve = {
        --   -- the path to the executable dlv which will be used for debugging.
        --   -- by default, this is the "dlv" executable on your PATH.
        --   path = 'dlv',
        --   -- time to wait for delve to initialize the debug session.
        --   -- default to 20 seconds
        --   initialize_timeout_sec = 20,
        --   -- a string that defines the port to start delve debugger.
        --   -- default to string "${port}" which instructs nvim-dap
        --   -- to start the process in a random available port.
        --   -- if you set a port in your debug configuration, its value will be
        --   -- assigned dynamically.
        --   port = '${port}',
        --   -- additional args to pass to dlv
        --   args = {},
        --   -- the build flags that are passed to delve.
        --   -- defaults to empty string, but can be used to provide flags
        --   -- such as "-tags=unit" to make sure the test suite is
        --   -- compiled during debugging, for example.
        --   -- passing build flags using args is ineffective, as those are
        --   -- ignored by delve in dap mode.
        --   -- available ui interactive function to prompt for arguments get_arguments
        --   build_flags = { '-tags=dev' },
        --   -- whether the dlv process to be created detached or not. there is
        --   -- an issue on Windows where this needs to be set to false
        --   -- otherwise the dlv server creation will fail.
        --   -- available ui interactive function to prompt for build flags: get_build_flags
        --   detached = vim.fn.has('win32') == 0,
        --   -- the current working directory to run dlv from, if other than
        --   -- the current working directory.
        --   cwd = nil,
        -- },
        -- -- options related to running closest test
        -- tests = {
        --   -- enables verbosity when running the test.
        --   verbose = false,
        -- },
      })

      -- require("nvim-dap-virtual-text").setup {
      --   -- This just tries to mitigate the chance that I leak tokens here. Probably won't stop it from happening...
      --   display_callback = function(variable)
      --     local name = string.lower(variable.name)
      --     local value = string.lower(variable.value)
      --     if name:match "secret" or name:match "api" or value:match "secret" or value:match "api" then
      --       return "*****"
      --     end
      --
      --     if #variable.value > 15 then
      --       return " " .. string.sub(variable.value, 1, 15) .. "... "
      --     end
      --
      --     return " " .. variable.value
      --   end,
      -- }

      -- Handled by nvim-dap-go
      -- dap.adapters.go = {
      --   type = "server",
      --   port = "${port}",
      --   executable = {
      --     command = "dlv",
      --     args = { "dap", "-l", "127.0.0.1:${port}" },
      --   },
      -- }
      require('dap-python').setup('uv')

      -- C/C++ debugging via codelldb (installed by Mason)
      local codelldb_path = vim.fn.stdpath('data') .. '/mason/packages/codelldb/extension/adapter/codelldb'

      dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        executable = {
          command = codelldb_path,
          args = { '--port', '${port}' },
        },
      }

      dap.configurations.c = {
        {
          name = 'Launch',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return coroutine.create(function(dap_run_co)
              vim.ui.input({ prompt = 'Path to executable: ', default = vim.fn.getcwd() .. '/' }, function(input)
                coroutine.resume(dap_run_co, input)
              end)
            end)
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
        {
          name = 'Attach to process',
          type = 'codelldb',
          request = 'attach',
          pid = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }
      dap.configurations.cpp = dap.configurations.c

      local function zig_build_and_pick()
        vim.notify('Running zig build...', vim.log.levels.INFO)
        local output = vim.fn.system('zig build 2>&1')
        if vim.v.shell_error ~= 0 then
          vim.notify('zig build failed:\n' .. output, vim.log.levels.ERROR)
          return nil
        end
        local bin_dir = vim.fn.getcwd() .. '/zig-out/bin'
        local bins = vim.fn.globpath(bin_dir, '*', false, true)
        bins = vim.tbl_filter(function(f)
          return vim.fn.executable(f) == 1
        end, bins)
        if #bins == 0 then
          vim.notify('No executables found in zig-out/bin/', vim.log.levels.ERROR)
          return nil
        end
        if #bins == 1 then
          return bins[1]
        end
        return coroutine.create(function(co)
          vim.ui.select(bins, { prompt = 'Select executable:' }, function(choice)
            coroutine.resume(co, choice)
          end)
        end)
      end

      local function zig_build_test()
        local file = vim.fn.expand('%:p')
        local bin_path = vim.fn.getcwd() .. '/zig-test-debug'
        vim.notify('Building test binary...', vim.log.levels.INFO)
        local output = vim.fn.system(
          'zig test --test-no-exec -femit-bin=' .. vim.fn.shellescape(bin_path) .. ' ' .. vim.fn.shellescape(file) .. ' 2>&1'
        )
        if vim.v.shell_error ~= 0 then
          vim.notify('Test build failed:\n' .. output, vim.log.levels.ERROR)
          return nil
        end
        return bin_path
      end

      dap.configurations.zig = {
        {
          name = 'Build & debug project',
          type = 'codelldb',
          request = 'launch',
          program = zig_build_and_pick,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
        {
          name = 'Debug test (current file)',
          type = 'codelldb',
          request = 'launch',
          program = zig_build_test,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
        {
          name = 'Attach to process',
          type = 'codelldb',
          request = 'attach',
          pid = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }

      vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'dap breakpoint' })
      vim.keymap.set('n', '<leader>gb', dap.run_to_cursor, { desc = 'dap run to cursor' })

      vim.keymap.set('n', '<leader>?', function()
        require('dapui').eval(nil, { enter = true })
      end, { desc = 'dap value under cursor' })

      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'dap continue' })
      vim.keymap.set('n', '<F7>', dap.step_into, { desc = 'dap step into' })
      vim.keymap.set('n', '<F8>', dap.step_over, { desc = 'dap step over' })
      vim.keymap.set('n', '<F9>', dap.step_out, { desc = 'dap step out' })
      vim.keymap.set('n', '<F10>', dap.step_back, { desc = 'dap step back' })
      vim.keymap.set('n', '<F11>', dap.restart, { desc = 'dap restart' })

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end

      vim.keymap.set('n', '<leader>u', function()
        ui.toggle()
      end, { desc = 'toggle debugger ui' })
    end,
  },
}
