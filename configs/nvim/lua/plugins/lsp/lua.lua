vim.lsp.config("lua_ls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})
vim.lsp.enable("lua_ls")

vim.lsp.config("gopls", {})
vim.lsp.enable("gopls")
