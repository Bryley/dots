require("options")
require("binds")


-- TODO LIST: for migrating to Neovim 0.12!
-- - [ ] Try to migrate away from `lazy.nvim` to the native plugin manager.
-- - [ ] Replace the plugin for smooth scrolling as something is lags and is buggy.
-- - [ ] Replace `nvim-cmp` with `blink.nvim`.
-- - [ ] Add Jira ticket autocomplete dropdown integration with blink.
-- - [ ] Clean up some of the LSP stuff to use the newer way of dealing with it.
-- - [ ] Migrate away from telescope to television and `tv.nvim`.
-- - [ ] Remove/fix the folding using Enter to either make it better or remove
--       entirely as it is not good enough.

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        {
            "abeldekat/lazyflex.nvim",
            version = "*",
            cond = true,
            import = "lazyflex.hook",
            opts = {
                enable_match = false,
                -- Put plugins (or a substring of plugin) to disable them
                kw = {
                    -- "cmp-async-path",
                    -- "cmp-buffer",
                    -- "cmp-cmdline",
                    --
                    -- "cmp-nvim-lsp",
                    -- "cmp-nvim-lua",
                    -- "nvim-cmp",
                },
            },
        },
        { import = "plugins" },
    },
})
