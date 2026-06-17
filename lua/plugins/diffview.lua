return {
    "sindrets/diffview.nvim",
    config = function()
        require("diffview").setup({
            view = {
                merge_tool = {
                    layout = "diff3_mixed",
                    disable_diagnostics = true, -- Temporarily disable diagnostics when in merge_tool
                },
            },
        })

        vim.keymap.set("n", "<leader>[", ":DiffviewFileHistory %<CR>", { silent = true })
        vim.keymap.set("n", "<leader>;", ":DiffviewClose <CR>", { silent = true })
    end
}
