return {
	"navarasu/onedark.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("onedark").setup({
			style = "warmer",
			-- onedark ships one colors/onedark.lua for all styles, so they
			-- can't show as separate entries in Telescope's colorscheme
			-- picker; toggle_style_key cycles through them instead.
			toggle_style_key = "<leader>ct",
			toggle_style_list = { "dark", "darker", "cool", "deep", "warm", "warmer", "light" },
		})
		require("onedark").load()
	end,
}
