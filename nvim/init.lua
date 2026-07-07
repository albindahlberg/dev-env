-- Set leader FIRST (before any keymaps)
vim.g.mapleader = " "

-- Load Lazy in both environments
-- Plugins with vscode=true (like flash.nvim) will load in VS Code
-- Everything else is automatically skipped
require("config.lazy")

-- Sets and remaps work in both environments (they have their own guards)
require("config.sets")
require("config.remap")

if vim.g.vscode then
	-- ==========================================================
	-- VS Code Neovim specific keymaps
	-- ==========================================================
	local vscode = require("vscode")

	-- --- Save / Close ---
	vim.keymap.set("n", "<leader>w", function()
		vscode.action("workbench.action.files.save")
	end, { desc = "Save file" })
	vim.keymap.set("n", "<leader>q", function()
		vscode.action("workbench.action.closeActiveEditor")
	end, { desc = "Close editor" })

	-- --- Search / Replace (override the native vim ones from remap.lua) ---
	vim.keymap.set("n", "<leader>s", function()
		vscode.action("actions.find")
	end, { desc = "Search in file" })
	vim.keymap.set("n", "<leader>S", function()
		vscode.action("editor.action.addSelectionToNextFindMatch")
	end, { desc = "Find word under cursor" })
	vim.keymap.set("n", "<leader>r", function()
		vscode.action("editor.action.startFindReplaceAction")
	end, { desc = "Replace in file" })
	vim.keymap.set("n", "<leader>R", function()
		vscode.action("editor.action.startFindReplaceAction")
	end, { desc = "Replace word under cursor" })
	vim.keymap.set("v", "<leader>R", function()
		vscode.action("editor.action.startFindReplaceAction")
	end, { desc = "Replace selection" })

	-- --- Telescope equivalents ---
	vim.keymap.set("n", "<leader>ff", function()
		vscode.action("workbench.action.quickOpen")
	end, { desc = "Find files" })
	vim.keymap.set("n", "<leader>lg", function()
		vscode.action("workbench.action.findInFiles")
	end, { desc = "Live grep" })
	vim.keymap.set("n", "<leader>of", function()
		vscode.action("workbench.action.openRecent")
	end, { desc = "Recent files" })
	vim.keymap.set("n", "<leader>fb", function()
		vscode.action("workbench.view.explorer")
	end, { desc = "File browser" })

	-- --- Oil equivalent ---
	vim.keymap.set("n", "-", function()
		vscode.action("workbench.files.action.showActiveFileInExplorer")
	end, { desc = "Reveal file in explorer" })

	-- --- Sidebar toggle ---
	vim.keymap.set("n", "<leader>e", function()
		vscode.action("workbench.action.toggleSidebarVisibility")
	end, { desc = "Toggle sidebar" })

	-- --- LSP (VS Code handles the actual language servers) ---
	vim.keymap.set("n", "gd", function()
		vscode.action("editor.action.revealDefinition")
	end)
	vim.keymap.set("n", "gr", function()
		vscode.action("editor.action.goToReferences")
	end)
	vim.keymap.set("n", "gi", function()
		vscode.action("editor.action.goToImplementation")
	end)
	vim.keymap.set("n", "K", function()
		vscode.action("editor.action.showHover")
	end)
	vim.keymap.set("n", "<leader>rn", function()
		vscode.action("editor.action.rename")
	end, { desc = "Rename symbol" })
	vim.keymap.set("n", "<leader>ca", function()
		vscode.action("editor.action.quickFix")
	end, { desc = "Code action" })

	-- --- Diagnostics ---
	vim.keymap.set("n", "]d", function()
		vscode.action("editor.action.marker.next")
	end)
	vim.keymap.set("n", "[d", function()
		vscode.action("editor.action.marker.prev")
	end)
	vim.keymap.set("n", "<leader>d", function()
		vscode.action("workbench.actions.view.problems")
	end, { desc = "Show problems panel" })

	-- --- Terminal ---
	vim.keymap.set("n", "<leader>T", function()
		vscode.action("workbench.action.terminal.toggleTerminal")
	end, { desc = "Toggle terminal" })
	vim.keymap.set("n", "<A-j>", function()
		vscode.action("workbench.action.terminal.toggleTerminal")
	end, { desc = "Toggle terminal" })

	-- --- Commenting ---
	vim.keymap.set("n", "gcc", function()
		vscode.action("editor.action.commentLine")
	end)
	vim.keymap.set("v", "gc", function()
		vscode.action("editor.action.commentLine")
	end)

	-- --- Buffer navigation ---
	vim.keymap.set("n", "<leader>b", function()
		vscode.action("workbench.action.openPreviousRecentlyUsedEditor")
	end, { desc = "Last buffer" })

	-- --- UndoTree → Local History ---
	vim.keymap.set("n", "<leader>u", function()
		vscode.action("workbench.action.localHistory.open")
	end, { desc = "Local history" })

	-- --- Quickfix → Problems panel ---
	vim.keymap.set("n", "<leader>nq", function()
		vscode.action("workbench.actions.view.problems")
	end, { desc = "Toggle problems" })

	-- --- Codex ---
	vim.keymap.set("n", "<leader>c", function()
		vscode.action("chatgpt.openSidebar")
	end, { desc = "Open Codex" })
	vim.keymap.set("n", "<leader>cn", function()
		vscode.action("chatgpt.newChat")
	end, { desc = "New Codex chat" })
	vim.keymap.set("n", "<A-h>", function()
		vscode.action("workbench.action.focusActiveEditorGroup")
	end, { desc = "Focus editor" })

	vim.keymap.set("n", "<leader>q", function()
		vscode.action("workbench.action.closeQuickOpen")
		vscode.action("hideSuggestWidget")
		vscode.action("closeParameterHints")
		vscode.action("cancelRenameInput")
		vscode.action("closeFindWidget")
		vscode.action("closeReferenceSearch")
		vscode.action("workbench.action.terminal.kill")
		vscode.action("workbench.action.closePanel")
		vscode.action("workbench.action.closeSidebar")
		vscode.action("workbench.action.closeAuxiliaryBar")
		vscode.action("workbench.action.closeActiveEditor")
	end, { silent = true, desc = "Close active UI/editor/panel" })

	-- --- Centered scrolling ---
	vim.keymap.set("n", "<C-d>", "<C-d>zz")
	vim.keymap.set("n", "<C-u>", "<C-u>zz")
	vim.keymap.set("n", "n", "nzzzv")
	vim.keymap.set("n", "N", "Nzzzv")

	vim.api.nvim_set_keymap("n", "§", "<Esc>", { noremap = true })
	vim.api.nvim_set_keymap("i", "§", "<Esc>", { noremap = true })
	vim.api.nvim_set_keymap("v", "§", "<Esc>", { noremap = true })
	vim.api.nvim_set_keymap("c", "§", "<Esc>", { noremap = true })

	-- § also clears search highlight in normal mode
	vim.keymap.set("n", "§", "<cmd>nohlsearch<CR>")
else
	-- ==========================================================
	-- Native Neovim only
	-- ==========================================================
	require("config.lsp")
end
