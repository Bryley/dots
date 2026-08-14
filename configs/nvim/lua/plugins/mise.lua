-- Mise task scripts are TOML, with shell (or shebang-selected) code embedded in
-- task `run` values. Otter forwards normal LSP requests from those injections.
vim.pack.add({
    "https://github.com/jmbuhr/otter.nvim",
})

vim.treesitter.query.add_predicate("is-mise?", function(_, _, bufnr)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(tonumber(bufnr) or 0), ":t")
    return filename:match(".*mise.*%.toml$") ~= nil
end, { force = true, all = false })

require("otter").setup()

vim.api.nvim_create_autocmd("FileType", {
    pattern = "toml",
    group = vim.api.nvim_create_augroup("mise_embedded_lsp", { clear = true }),
    callback = function(args)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":t")
        if filename:match(".*mise.*%.toml$") then
            require("otter").activate()
        end
    end,
})
