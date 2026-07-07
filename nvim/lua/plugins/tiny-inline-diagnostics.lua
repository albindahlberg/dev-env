return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
        diag = require("tiny-inline-diagnostic")
        diag.setup({
            preset = "powerline",
        })
        diag.enable()
        vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
    end,
}
