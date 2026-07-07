return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_organize_imports", "ruff_format" },
			rust = { "rustfmt" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			sql = { "sql_formatter" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	},
}
