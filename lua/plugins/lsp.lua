return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-nvim-lsp',
            'L3MON4D3/LuaSnip',
        },
        config = function()
            local m_status, mason = pcall(require, "mason")
            local ml_status, mason_lsp = pcall(require, "mason-lspconfig")
            local lc_status, lspconfig = pcall(require, "lspconfig")

            if not (m_status and ml_status and lc_status and mason_lsp.setup_handlers) then
                return
            end

            mason.setup()
            mason_lsp.setup({
                ensure_installed = {
                    'rust_analyzer', 'svelte', 'ts_ls',
                    'pyright', 'clangd', 'marksman', 'ocamllsp'
                }
            })

            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            mason_lsp.setup_handlers({
                function(server_name)
                    lspconfig[server_name].setup({
                        capabilities = capabilities,
                    })
                end,
                ["pyright"] = function()
                    lspconfig.pyright.setup({
                        capabilities = capabilities,
                        settings = {
                            python = {
                                analysis = {
                                    typeCheckingMode = "basic",
                                    autoSearchPaths = true,
                                    useLibraryCodeForTypes = true,
                                },
                            },
                        },
                    })
                end,
            })

            local c_status, cmp = pcall(require, "cmp")
            if c_status then
                cmp.setup({
                    snippet = {
                        expand = function(args)
                            require('luasnip').lsp_expand(args.body)
                        end,
                    },
                    mapping = cmp.mapping.preset.insert({
                        ['<C-Space>'] = cmp.mapping.complete(),
                        ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    }),
                    sources = cmp.config.sources({
                        { name = 'nvim_lsp' },
                        { name = 'luasnip' },
                    }, {
                        { name = 'buffer' },
                    })
                })
            end
        end
    }
}
