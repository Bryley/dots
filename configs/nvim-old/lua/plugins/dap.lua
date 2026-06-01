return {
    {
        "mfussenegger/nvim-dap",
        config = function()
            -- Better Icons
            vim.fn.sign_define("DapBreakpoint", { text = " ", texthl = "Title", linehl = "", numhl = "" })
            vim.fn.sign_define(
                "DapBreakpointCondition",
                { text = " ", texthl = "DiagnosticFloatingInfo", linehl = "", numhl = "" }
            )
            vim.fn.sign_define("DapStopped", { text = "󰁙 ", texthl = "", linehl = "TermCursor", numhl = "" })

            local dap = require("dap")
            dap.adapters.codelldb = {
                type = "server",
                host = "127.0.0.1",
                port = "${port}",
                executable = {
                    command = vim.env.HOME .. "/.local/opt/codelldb/extension/adapter/codelldb",
                    args = { "--port", "${port}" },
                },
            }

            dap.configurations.rust = {
                {
                    type = "codelldb",
                    request = "launch",
                    name = "Launch file",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                },
            }
        end,
    },
    {
        -- Debugger user interface
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        config = function()
            require("dapui").setup()
        end,
    },
    {
        "leoluz/nvim-dap-go",
        dependencies = { "mfussenegger/nvim-dap" },
        ft = "go",
        config = function()
            require("dap-go").setup()
        end,
    },
}
