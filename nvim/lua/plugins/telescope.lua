return {
	"nvim-telescope/telescope.nvim", -- Telescope plugin repository
	tag = "v0.2.0", -- Specify the version tag (v0.2.0)
	dependencies = { "nvim-lua/plenary.nvim" }, -- Plenary is required for Telescope

	config = function()
		-- Basic Telescope setup
		require("telescope").setup({
			pickers = {
				find_files = {
					hidden = true,
				},
				live_grep = {
					additional_args = { "--hidden" },
				},
			},
			defaults = {
				-- Basic configuration options
				prompt_prefix = " ", -- Prompt symbol for Telescope
				selection_caret = "➤ ", -- Symbol for the selected item
				layout_strategy = "horizontal", -- Default layout strategy
				layout_config = {
					width = 0.75, -- Width of the Telescope window
					preview_width = 0.5, -- Width for the preview window
				},
			},
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "TelescopePrompt",
				callback = function(ev)
					vim.bo[ev.buf].bufhidden = "delete"
					vim.keymap.set("n", "<leader>q", function()
						require("telescope.actions").close(ev.buf)
					end, { buffer = ev.buf })
				end,
			}),
		})
		-- Apply the theme
		vim.cmd("colorscheme onedark")
	end,
}
