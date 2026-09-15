return {
	"datsfilipe/vesper.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		-- ponytail: lightened bg ladder (vesper ships dark-only, no light variant)
		require("vesper").setup({
			palette_overrides = {
				bg = "#232323",
				bgDark = "#282828",
				bgDarker = "#2E2E2E",
				bgFloat = "#343434",
			},
		})
		vim.cmd.colorscheme("vesper")
	end,
}
