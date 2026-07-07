return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	vscode = true,
	opts = {
		-- Configuration options for which-key (if any)
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
