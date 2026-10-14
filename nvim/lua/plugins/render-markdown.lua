return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	ft = "markdown",
	keys = {
		{ "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", ft = "markdown", desc = "Toggle markdown render" },
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		win_options = {
			wrap = { default = false, rendered = true },
			linebreak = { default = false, rendered = true },
		},
	},
}
