local coq = require("coq")

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.server_capabilities then
			client.server_capabilities.semanticTokensProvider = nil
		end
		local bufnr = args.buf
		vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP hover" })
	end,
})

require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"ty",
		"ruff",
		"rust_analyzer",
		"postgres_lsp",
		"marksman",
		"bashls",
		"yamlls",
		"sqlls",
	},
})

-- Configure servers using the new vim.lsp.config API
vim.lsp.config("*", coq.lsp_ensure_capabilities({}))

vim.lsp.config(
	"ruff",
	coq.lsp_ensure_capabilities({
		on_attach = function(client, bufnr)
			client.server_capabilities.hoverProvider = false
			vim.keymap.set("n", "<leader>cf", function()
				vim.lsp.buf.code_action({
					context = { only = { "source.fixAll" } },
					apply = true,
				})
			end, { buffer = bufnr, desc = "Ruff: Fix all" })
		end,
	})
)

vim.lsp.config(
	"bashls",
	coq.lsp_ensure_capabilities({
		filetypes = { "sh", "bash", "zsh" },
		settings = {
			bashIde = {
				globPattern = "*@(.sh|.bash|.zsh|.bashrc|.bash_profile|.bash_login|.bash_logout|.bash_aliases)",
			},
		},
	})
)

vim.lsp.config(
	"postgres_lsp",
	coq.lsp_ensure_capabilities({
		filetypes = { "sql" },
	})
)

vim.lsp.enable({
	"ty",
	"ruff",
	"lua_ls",
	"rust_analyzer",
	"bashls",
	"marksman",
	"postgres_lsp",
	"yamlls",
})
