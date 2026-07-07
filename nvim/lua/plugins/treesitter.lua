return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
            })
            local select = require("nvim-treesitter-textobjects.select")
            local function map(key, query)
                vim.keymap.set({ "x", "o" }, key, function()
                    select.select_textobject(query, "textobjects")
                end)
            end

            -- functions
            map("af", "@function.outer")
            map("if", "@function.inner")
            -- classes
            map("ac", "@class.outer")
            map("ic", "@class.inner")
            -- parameters/arguments
            map("aa", "@parameter.outer")
            map("ia", "@parameter.inner")
            -- conditionals
            map("ai", "@conditional.outer")
            map("ii", "@conditional.inner")
            -- loops
            map("al", "@loop.outer")
            map("il", "@loop.inner")
            -- comments
            map("ao", "@comment.outer")
            map("io", "@comment.inner")
        end,
    },
}
