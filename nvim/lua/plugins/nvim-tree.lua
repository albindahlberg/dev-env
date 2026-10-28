return {
	"nvim-tree/nvim-tree.lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle" },
	keys = {
		{ "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", desc = "File tree" },
	},
	opts = {
		hijack_netrw = false,
		hijack_directories = { enable = false },
		renderer = { icons = { show = { git = false } } },
		on_attach = function(bufnr)
			local api = require("nvim-tree.api")
			api.config.mappings.default_on_attach(bufnr)
			vim.keymap.set("n", "<CR>", api.node.open.preview, { buffer = bufnr, desc = "Open: Preview" })
		end,
	},
}
