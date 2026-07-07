-- ============================================================
-- config/sets.lua — options that work in both neovim and vscode
-- ============================================================

-- These vim options matter for the embedded neovim engine
-- (motions, search behavior, indent behavior, clipboard)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"

-- Strip \r from yanked content
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		local reg = vim.fn.getreg(vim.v.event.regname ~= "" and vim.v.event.regname or '"')
		local cleaned = reg:gsub("\r", "")
		if cleaned ~= reg then
			vim.fn.setreg(vim.v.event.regname ~= "" and vim.v.event.regname or '"', cleaned)
		end
	end,
})

-- Yank highlight
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	callback = function()
		vim.hl.on_yank()
	end,
})

if not vim.g.vscode then
	-- ==========================================================
	-- Native Neovim only: visual/UI options
	-- (VS Code controls these via settings.json)
	-- ==========================================================
	vim.opt.wrap = false
	vim.opt.swapfile = false
	vim.opt.backup = false
	vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
	vim.opt.undofile = true
	vim.opt.termguicolors = true
	vim.o.number = true
	vim.o.relativenumber = true
	vim.o.cursorline = true
	vim.o.scrolloff = 10
	vim.o.list = true
	vim.o.confirm = true
	vim.o.autoread = true

	-- Auto-check for file changes
	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
		command = "checktime",
	})
	vim.api.nvim_create_autocmd("FileChangedShellPost", {
		callback = function()
			vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
		end,
	})

	-- Jump to last cursor position
	local lastplace = vim.api.nvim_create_augroup("LastPlace", {})
	vim.api.nvim_clear_autocmds({ group = lastplace })
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = lastplace,
		pattern = { "*" },
		desc = "remember last cursor place",
		callback = function()
			local mark = vim.api.nvim_buf_get_mark(0, '"')
			local lcount = vim.api.nvim_buf_line_count(0)
			if mark[1] > 0 and mark[1] <= lcount then
				pcall(vim.api.nvim_win_set_cursor, 0, mark)
			end
		end,
	})

	-- Python filetype settings
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		callback = function()
			vim.bo.tabstop = 4
			vim.bo.shiftwidth = 4
			vim.bo.expandtab = true
			vim.wo.colorcolumn = "88"
		end,
	})

	-- Treesitter
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "python", "rust", "yaml", "json", "sql" },
		callback = function()
			vim.treesitter.start()
		end,
	})

	-- Git blame command
	vim.api.nvim_create_user_command("GitBlameLine", function()
		local line_number = vim.fn.line(".")
		local filename = vim.api.nvim_buf_get_name(0)
		print(vim.fn.system({ "git", "blame", "-L", line_number .. ",+1", filename }))
	end, { desc = "Print the git blame for the current line" })
end
