return {
    {
        'williamboman/mason.nvim',
        build = ':MasonUpdate',
        lazy = false,
        config = true,
    },
    {
        'neovim/nvim-lspconfig',
        config = function()
            vim.lsp.config('lua_ls', {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if
                            path ~= vim.fn.stdpath('config')
                            and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                        then
                            return
                        end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                        runtime = {
                            -- Tell the language server which version of Lua you're using (most
                            -- likely LuaJIT in the case of Neovim)
                            version = 'LuaJIT',
                            -- Tell the language server how to find Lua modules same way as Neovim
                            -- (see `:h lua-module-load`)
                            path = {
                                'lua/?.lua',
                                'lua/?/init.lua',
                            },
                        },
                        -- Make the server aware of Neovim runtime files
                        workspace = {
                            checkThirdParty = false,
                            library = {
                                vim.env.VIMRUNTIME
                                -- Depending on the usage, you might want to add additional paths
                                -- here.
                                -- '${3rd}/luv/library'
                                -- '${3rd}/busted/library'
                            }
                            -- Or pull in all of 'runtimepath'.
                            -- NOTE: this is a lot slower and will cause issues when working on
                            -- your own configuration.
                            -- See https://github.com/neovim/nvim-lspconfig/issues/3189
                            -- library = {
                            --   vim.api.nvim_get_runtime_file('', true),
                            -- }
                        }
                    })
                end,
                settings = {
                    Lua = {}
                }
            })

            vim.lsp.config("denols", {
                workspace_required = true,
                root_dir = function(_, callback)
                    local root_dir = vim.fs.root(0, { "deno.json", "deno.jsonc" })

                    if root_dir then
                        callback(root_dir)
                    end
                end,
            })

            vim.lsp.config("vtsls", {
                workspace_required = true,
                settings = {
                    refactor_auto_rename = true,
                    complete_function_calls = true,
                    vtsls = {
                        enableMoveToFileCodeAction = true,
                        autoUseWorkspaceTsdk = true,
                        experimental = {
                            completion = {
                                enableServerSideFuzzyMatch = true,
                                entriesLimit = 20,
                            },
                        }
                    },
                    typescript = {
                        format = {
                            enable = false
                        },
                        inlayHints = {
                            parameterNames = { enabled = "literals" },
                            parameterTypes = { enabled = true },
                            variableTypes = { enabled = true },
                            propertyDeclarationTypes = { enabled = true },
                            functionLikeReturnTypes = { enabled = true },
                            enumMemberValues = { enabled = true },
                        },
                        updateImportsOnFileMove = { enabled = "always" },
                        suggest = {
                            completeFunctionCalls = true,
                            autoImports = true
                        },
                        tsserver = {
                            useSeparateSyntaxServer = true,
                            experimental = {
                                enableProjectDiagnostics = true,
                            },
                        },
                        preferences = {
                            -- importModuleSpecifier = "project-relative",
                            importModuleSpecifier = "shortest",
                            includePackageJsonAutoImports = "on",
                            preferTypeOnlyAutoImports = true
                        },
                    },
                },
                root_dir = function(_, callback)
                    local deno_dir = vim.fs.root(0, { "deno.json", "deno.jsonc" })
                    local root_dir = vim.fs.root(0, { "tsconfig.json", "jsconfig.json", "package.json" })

                    if root_dir and deno_dir == nil then
                        callback(root_dir)
                    end
                end,
            })

            vim.lsp.config("eslint", {
                workspace_required = true,
            })

            -- Creating a simple setTimeout wrapper
            local function setTimeout(timeout, callback)
                local timer = vim.uv.new_timer()
                timer:start(timeout, 0, function()
                    timer:stop()
                    timer:close()
                    callback()
                end)
                return timer
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    -- Keymaps

                    local opts = { buffer = args.buf }

                    vim.keymap.set('n', '<C-Space>', '<C-x><C-o>', opts)
                    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
                    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
                    vim.keymap.set({ 'n', 'x' }, 'gq', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)

                    vim.keymap.set('n', 'grt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
                    vim.keymap.set('n', 'grd', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)

                    vim.keymap.set("n", "<F2>", ':lua vim.lsp.buf.rename()<CR>', { silent = true })
                    vim.keymap.set("n", "<F4>", ':lua vim.lsp.buf.code_action()<CR>', { silent = true })
                    vim.keymap.set("n", "<C-space>", ':lua vim.lsp.buf.hover()<CR>', { silent = true })

                    --[[
                    vim.keymap.set("n", "<F9>", function()
                        vim.lsp.stop_client(vim.lsp.get_active_clients())
                        vim.api.nvim_command(':e')
                    end, { noremap = true, silent = true })
                    ]]

                    vim.keymap.set("n", "<F9>", '<cmd>LspRestart<CR>', { noremap = true, silent = true })


                    -- Autocompletion

                    vim.keymap.set("i", "<C-space>", vim.lsp.completion.get, { desc = "Trigger autocompletion" })

                    -- Prevent the built-in vim.lsp.completion autotrigger from selecting the first item
                    vim.opt.completeopt = { "menuone", "noselect", "popup" }

                    local client = vim.lsp.get_client_by_id(args.data.client_id)

                    if client:supports_method('textDocument/completion') then
                        vim.lsp.completion.enable(true, client.id, args.buf, {
                            autotrigger = true,
                        })
                    end

                    -- Format on save
                    if client:supports_method('textDocument/formatting') then
                        vim.api.nvim_create_autocmd('BufWritePre', {
                            buffer = args.buf,
                            callback = function()
                                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
                            end,
                        })
                    end
                end,
            })

            -- this is for diagnositcs signs on the line number column
            -- use this to beautify the plain E W signs to more fun ones
            -- !important nerdfonts needs to be setup for this to work in your terminal
            vim.diagnostic.config({
                virtual_text = true,
                signs = true,
                update_in_insert = false,
                underline = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN] = " ",
                        [vim.diagnostic.severity.INFO] = " ",
                        [vim.diagnostic.severity.HINT] = " ",
                    },
                    texthl = {
                        [vim.diagnostic.severity.ERROR] = "Error",
                        [vim.diagnostic.severity.WARN] = "Warning",
                        [vim.diagnostic.severity.INFO] = "Info",
                        [vim.diagnostic.severity.HINT] = "Hint",
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "",
                        [vim.diagnostic.severity.WARN] = "",
                        [vim.diagnostic.severity.INFO] = "",
                        [vim.diagnostic.severity.HINT] = "",
                    }
                }
            })

            --[[
            vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
                vim.lsp.diagnostic.on_publish_diagnostics,
                {
                    virtual_text = true,
                    signs = true,
                    update_in_insert = false,
                    underline = true,
                }
            )
            --]]

            vim.g.markdown_fenced_languages = {
                "ts=typescript"
            }

            vim.lsp.enable({
                "vtsls",
                "rust_analyzer",
                "denols",
                "eslint",
                "cssls",
                "jsonls",
                "pyright",
                "lua_ls",
                "taplo",
                "gh_actions_ls",
                "terraformls",
                "gopls",
                "yamlls",
                "csharp_ls",
                "gh_actions_ls",
                --"angularls",
                --"tsgo"
            });
        end
    },
}
