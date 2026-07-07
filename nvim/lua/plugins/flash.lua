return {
	"folke/flash.nvim",
	event = "VeryLazy",
	vscode = true,
	opts = {
		modes = {
			char = {
				enabled = false, -- disables the f/F/t/T enhancement
			},
		},
	},
	init = function()
		vim.keymap.set({ "n", "x", "o" }, "f", function()
			require("flash").jump()
		end, { desc = "Flash", noremap = true })
		vim.keymap.set({ "n", "x", "o" }, "F", function()
			require("flash").treesitter()
		end, { desc = "Flash Treesitter", noremap = true })
	end,
}
