return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.1',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" }
    },
    config = function()
        local builtin = require('telescope.builtin')
        local telescope = require('telescope')

        -- Load the live_grep_args extension
        telescope.load_extension('live_grep_args')

        telescope.setup({
            defaults = {
                file_ignore_patterns = {
                    "node_modules",
                    "dist",
                    "build",
                    "^.git/"
                },
            },
            pickers = {
                find_files = {
                    -- Don't show the full path, just the filename
                    path_display = { shorten = { len = 2, exclude = {-1, -2} } },
                    no_ignore = true, -- Don't ignore files in .gitignore
                    hidden = true, -- Show hidden files
                },
                live_grep = {
                    additional_args = function()
                        return { "--no-ignore", "--hidden" } -- Include hidden files in live_grep
                    end,
                }
            }
        })

        -- Setup keymaps
        vim.keymap.set('n', '<leader>ff',
            ":lua require('telescope.builtin').find_files()<CR>",
            {})
        vim.keymap.set('n', '<leader>fg', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", {})
        vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
        vim.keymap.set("n", '<leader>fs', function()
            vim.ui.input({ prompt = "Workspace symbols: " }, function(query)
                builtin.lsp_workspace_symbols({ query = query })
            end)
        end, { desc = "LSP workspace symbols" })
        vim.keymap.set("n", '<leader>fds', builtin.lsp_document_symbols, {})
    end
}
