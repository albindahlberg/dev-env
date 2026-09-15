return {
	"datsfilipe/vesper.nvim",
	lazy = true, -- lazy.nvim auto-loads on `:colorscheme vesper`
	config = function()
		-- ponytail: lightened bg ladder (vesper ships dark-only, no light variant)
		require("vesper").setup({
			palette_overrides = {
				bg = "#232323",
				bgDark = "#282828",
				bgDarker = "#2E2E2E",
				bgFloat = "#343434",
			},
			-- ponytail: upstream mistyped these treesitter capture names
			-- (e.g. "@text.literal" became "@texcolors.literal"), so they
			-- never matched real captures. Re-add under the correct names.
			overrides = {
				["@text.literal"] = { link = "Property" },
				["@text.strong"] = { link = "Bold" },
				["@text.italic"] = { link = "Italic" },
				["@text.title"] = { link = "Keyword" },
				["@text.uri"] = { fg = "#82D9C2", sp = "#82D9C2", underline = true },
				["@text.underline"] = { link = "Underlined" },
				["@text.todo"] = { link = "Todo" },
				["@text.diff.add"] = { fg = "#82D9C2" },
				["@text.diff.delete"] = { fg = "#FF8080" },
				["@constant.builtin"] = { link = "Keyword" },
				["@label.help"] = { link = "@text.uri" },
				["@text.uri.html"] = { underline = true },
			},
		})
	end,
}
