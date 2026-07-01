return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local status_ok, configs = pcall(require, "nvim-treesitter.configs")
        if not status_ok then
            return
        end

        configs.setup({
            ensure_installed = {
                "rust", "python", "c", "cpp", "dockerfile", "gitattributes",
                "gitignore", "html", "css", "java", "lua", "markdown",
                "ocaml", "r", "sql", "strace", "svelte", "tmux", "tsx",
                "toml", "markdown_inline", "vim", "vimdoc", "asm"
            },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end
}
