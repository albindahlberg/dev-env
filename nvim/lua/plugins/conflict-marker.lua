return {
	"tronikelis/conflict-marker.nvim",
	config = function()
		require("conflict-marker").setup({
			highlights = true,
			on_attach = function(conflict)
				local map = function(key, fn)
					vim.keymap.set("n", key, fn, { buffer = conflict.bufnr })
				end

				-- or you can map these to <cmd>Choose ours<cr>

				map("co", function()
					conflict:choose_ours()
				end)
				map("ct", function()
					conflict:choose_theirs()
				end)
				map("cb", function()
					conflict:choose_both()
				end)
				map("cn", function()
					conflict:choose_none()
				end)
			end,
			markers = {
				start = "^<<<<<<<",
				ending = "^>>>>>>>",
				mid = "^=======$",
				base = "^|||||||",
			},
		})
	end,
}
