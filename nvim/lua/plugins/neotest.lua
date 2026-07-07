return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
  },

  config = function()
    require("neotest").setup {
        adapters = {
           require("neotest-python")({
              dap = { justMyCode = false },
            }),
        },
    }

    vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run tests in file" })
    vim.keymap.set("n", "<leader>ta", function() require("neotest").run.run(vim.fn.getcwd()) end, { desc = "Run all tests" })
    vim.keymap.set("n", "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, { desc = "Debug nearest test" })
    vim.keymap.set("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Open test output" })
    vim.keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Toggle test summary" })
end,
}
