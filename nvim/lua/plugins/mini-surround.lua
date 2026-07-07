return {
	"nvim-mini/mini.surround",
	version = "*",
	vscode = true,
	config = function()
		require("mini.surround").setup()
	end,
}
