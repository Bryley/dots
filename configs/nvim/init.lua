require("options")

-- TODO LIST:
-- [X] Smooth scrolling
-- [X] LSP and Null ls
-- [X] Telescope
-- [X] Colorscheme select telescope
-- [X] Git signs
-- [X] Visual mode block keep
-- [X] control backspace

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

require("lazy").setup("plugins", {
    defaults = {
        -- lazy = false,
        cond = function (plugin)

            return true
            -- Used for debugging
            -- local ENABLED = {
            --     "SmiteshP/nvim-navic",
            --     "MunifTanjim/nui.nvim",
            --     "SmiteshP/nvim-navbuddy",
            --     "nvim-lualine/lualine.nvim",
            --     "nvim-lua/plenary.nvim",
            --     "neovim/nvim-lspconfig",
            --     "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            --     "folke/neodev.nvim",
            --     "hrsh7th/cmp-nvim-lsp",
            --     "jose-elias-alvarez/null-ls.nvim",
            --     "b0o/schemastore.nvim",
            -- }
            -- local name = plugin[1]
            -- if name == nil then
            --     return true
            -- end
            -- if vim.tbl_contains(ENABLED, name) then
            --     vim.print(name)
            --     return true
            -- end
            -- return false
        end,
    }
})
require("keybinds")
require("autocmds")
