-- ============================================================
-- config/remap.lua — keymaps for both neovim and vscode
-- ============================================================

vim.g.mapleader = " "

-- ==========================================================
-- Universal keymaps (work in both native nvim and vscode nvim)
-- ==========================================================

-- § as Escape (Swedish keyboard)
vim.api.nvim_set_keymap("n", "§", "<Esc>", { noremap = true })
vim.api.nvim_set_keymap("i", "§", "<Esc>", { noremap = true })
vim.api.nvim_set_keymap("v", "§", "<Esc>", { noremap = true })
vim.api.nvim_set_keymap("c", "§", "<Esc>", { noremap = true })

-- § also clears search highlight in normal mode
vim.keymap.set("n", "§", "<cmd>nohlsearch<CR>")

-- Don't overwrite yank after paste
vim.keymap.set("n", "p", "p")
vim.keymap.set("x", "p", '"_dP')

-- Indent with Tab
vim.keymap.set("n", "<Tab>", ">>", { noremap = true })
vim.keymap.set("n", "<S-Tab>", "<<", { noremap = true })
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true })

-- Move lines up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move lines down", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move lines up", silent = true })
vim.keymap.set("n", "J", ":m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "K", ":m .-2<CR>==", { desc = "Move line up", silent = true })

-- Create new lines without entering insert
vim.keymap.set("n", "<CR>", "o<Esc>")

-- Disable Q
vim.keymap.set("n", "Q", "<nop>")

-- Clean \r newlines
vim.keymap.set("n", "<leader>c", "<cmd>%s/\\r//<CR>", { desc = "Clear \\r" })

-- Escape from terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- ==========================================================
-- Native Neovim only keymaps (plugins, terminal, tmux, etc.)
-- ==========================================================
if not vim.g.vscode then
	-- Write / Quit
	vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Write file" })
	vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit buffer" })

	-- Search
	vim.keymap.set("n", "<leader>s", function()
		vim.api.nvim_input(":/")
	end, { desc = "Search" })

	vim.keymap.set("n", "<leader>S", function()
		local word = vim.fn.expand("<cword>")
		vim.api.nvim_input(":/" .. word .. "<CR>")
	end, { desc = "Search word under cursor" })

	-- Replace
	vim.keymap.set("n", "<leader>r", function()
		vim.api.nvim_input(":%s/")
	end, { desc = "Replace" })

	vim.keymap.set("n", "<leader>R", function()
		local word = vim.fn.expand("<cword>")
		vim.api.nvim_input(":<C-u>%s/\\v(" .. word .. ")/" .. word .. "/gI<Left><Left><Left>")
	end, { desc = "Replace word under cursor" })

	vim.keymap.set("v", "<leader>R", function()
		vim.cmd('noau normal! "zy')
		local selection = vim.fn.getreg("z")
		selection = vim.fn.escape(selection, "/\\")
		vim.api.nvim_input(":<C-u>%s/\\v(" .. selection .. ")/" .. selection .. "/gI<Left><Left><Left>")
	end, { desc = "Replace selection" })

	-- § terminal escape
	vim.api.nvim_set_keymap("t", "§", "<C-\\><C-n>", { noremap = true })

	-- Telescope
	vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
	vim.keymap.set("n", "<leader>lg", "<cmd>Telescope live_grep<CR>")
	vim.keymap.set("n", "<leader>of", "<cmd>Telescope oldfiles<CR>")
	vim.keymap.set("n", "<leader>fb", "<cmd>Telescope file_browser<CR>")

	-- UndoTree
	vim.keymap.set(
		"n",
		"<leader>u",
		require("undotree").toggle,
		{ noremap = true, silent = true, desc = "Toggle UndoTree" }
	)

	-- Oil
	vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

	-- Quickfix navigation
	vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>")
	vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>")

	-- Quickfix toggle
	local function toggle_quickfix_and_maybe_clear()
		local qf_is_open = false
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].buftype == "quickfix" then
				qf_is_open = true
				break
			end
		end
		require("quicker").toggle()
		if qf_is_open then
			vim.fn.setqflist({})
		end
	end

	vim.keymap.set("n", "<leader>nq", toggle_quickfix_and_maybe_clear, {
		desc = "Toggle quickfix (and clear when closing)",
	})

	-- Last buffer
	vim.keymap.set("n", "<leader>b", "<cmd>b#<CR>", { desc = "Go to last buffer" })

	-- LSP
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })

	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition({
			on_list = function(options)
				if #options.items == 0 then
					return
				end
				local item = options.items[1]
				vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
				vim.api.nvim_win_set_cursor(0, { item.lnum, (item.col or 1) - 1 })
			end,
		})
	end, { desc = "Go to definition", noremap = true, silent = true })
	vim.keymap.set("n", "gw", function()
		vim.lsp.buf.definition({
			on_list = function(options)
				if #options.items == 0 then
					return
				end
				local item = options.items[1]
				local uri = item.filename or vim.uri_from_bufnr(item.bufnr)
				local buf = vim.uri_to_bufnr(vim.uri_from_fname(uri))
				vim.fn.bufload(buf)

				-- shorten to relative path or just the filename
				local title = " " .. vim.fn.fnamemodify(uri, ":~:.") .. " "

				local width = math.floor(vim.o.columns * 0.7)
				local height = math.floor(vim.o.lines * 0.7)
				local win = vim.api.nvim_open_win(buf, true, {
					relative = "editor",
					width = width,
					height = height,
					col = math.floor((vim.o.columns - width) / 2),
					row = math.floor((vim.o.lines - height) / 2),
					style = "minimal",
					border = "rounded",
					title = title,
					title_pos = "center",
				})

				local lnum = item.lnum or 1
				local col = item.col and (item.col - 1) or 0
				vim.api.nvim_win_set_cursor(win, { lnum, col })

				vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
			end,
		})
	end, { desc = "Peek definition in float", noremap = true, silent = true })
	-- Diagnostics to quickfix (filtered to cwd)
	vim.keymap.set("n", "<leader>d", function()
		vim.diagnostic.setqflist()
		local cwd = vim.fn.getcwd()
		local filtered = vim.tbl_filter(function(item)
			local fname = vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ":p")
			return vim.startswith(fname, cwd)
		end, vim.fn.getqflist())
		vim.fn.setqflist(filtered, "r")
	end, { desc = "Diagnostics to quickfix (cwd)" })

	-- Tmux navigator (Alt+hjkl)
	vim.g.tmux_navigator_no_mappings = 1
	vim.keymap.set("n", "<A-h>", ":TmuxNavigateLeft<CR>", { silent = true })
	vim.keymap.set("n", "<A-j>", ":TmuxNavigateDown<CR>", { silent = true })
	vim.keymap.set("n", "<A-k>", ":TmuxNavigateUp<CR>", { silent = true })
	vim.keymap.set("n", "<A-l>", ":TmuxNavigateRight<CR>", { silent = true })

	vim.keymap.set("i", "<A-h>", "<C-\\><C-n>:TmuxNavigateLeft<CR>", { silent = true })
	vim.keymap.set("i", "<A-j>", "<C-\\><C-n>:TmuxNavigateDown<CR>", { silent = true })
	vim.keymap.set("i", "<A-k>", "<C-\\><C-n>:TmuxNavigateUp<CR>", { silent = true })
	vim.keymap.set("i", "<A-l>", "<C-\\><C-n>:TmuxNavigateRight<CR>", { silent = true })

	vim.keymap.set("t", "<A-h>", "<C-\\><C-n>:TmuxNavigateLeft<CR>", { silent = true })
	vim.keymap.set("t", "<A-j>", "<C-\\><C-n>:TmuxNavigateDown<CR>", { silent = true })
	vim.keymap.set("t", "<A-k>", "<C-\\><C-n>:TmuxNavigateUp<CR>", { silent = true })
	vim.keymap.set("t", "<A-l>", "<C-\\><C-n>:TmuxNavigateRight<CR>", { silent = true })

	-- Terminal toggle
	local term_buf_v = nil
	local term_win_v = nil

	local function toggle_terminal_vertical()
		if vim.bo.buftype == "terminal" then
			vim.cmd("hide")
			return
		end
		if term_buf_v and vim.api.nvim_buf_is_valid(term_buf_v) then
			if term_win_v and vim.api.nvim_win_is_valid(term_win_v) then
				vim.api.nvim_set_current_win(term_win_v)
			else
				vim.cmd("botright vsplit")
				term_win_v = vim.api.nvim_get_current_win()
				vim.api.nvim_win_set_buf(term_win_v, term_buf_v)
				vim.api.nvim_win_set_width(term_win_v, vim.api.nvim_win_get_width(term_win_v) - 10)
			end
		else
			vim.cmd("botright vsplit | terminal")
			term_buf_v = vim.api.nvim_get_current_buf()
			term_win_v = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_width(term_win_v, vim.api.nvim_win_get_width(term_win_v) - 10)
		end
		vim.cmd("startinsert")
	end

	local function leader_cc()
		if term_buf_v and vim.api.nvim_buf_is_valid(term_buf_v) then
			if term_win_v and vim.api.nvim_win_is_valid(term_win_v) then
				vim.api.nvim_set_current_win(term_win_v)
			else
				vim.cmd("botright vsplit")
				term_win_v = vim.api.nvim_get_current_win()
				vim.api.nvim_win_set_buf(term_win_v, term_buf_v)
				vim.api.nvim_win_set_width(term_win_v, vim.api.nvim_win_get_width(term_win_v) - 10)
			end
			vim.cmd("startinsert")
		else
			vim.cmd("botright vsplit | terminal codex")
			term_buf_v = vim.api.nvim_get_current_buf()
			term_win_v = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_width(term_win_v, vim.api.nvim_win_get_width(term_win_v) - 10)
			vim.cmd("startinsert")
		end
	end

	vim.keymap.set("n", "<leader>T", toggle_terminal_vertical, {
		desc = "Toggle vertical terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>cc", leader_cc, {
		desc = "Focus terminal or launch Codex CLI",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>mc", function()
		vim.cmd("botright 10split | terminal make check")
	end, {
		desc = "Run make check in bottom terminal",
		noremap = true,
		silent = true,
	})
	local function run_cmd_in_float(cmd, title)
		local width = math.floor(vim.o.columns * 0.9)
		local height = math.floor(vim.o.lines * 0.85)
		local col = math.floor((vim.o.columns - width) / 2)
		local row = math.floor((vim.o.lines - height) / 2)

		local buf = vim.api.nvim_create_buf(false, true)
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			col = col,
			row = row,
			style = "minimal",
			border = "rounded",
			title = " " .. title .. " ",
			title_pos = "center",
		})

		vim.fn.termopen(cmd)
		vim.cmd("startinsert")

		vim.keymap.set("n", "q", function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end, { buffer = buf, silent = true, nowait = true, desc = "Close " .. title .. " window" })
	end

	vim.keymap.set("n", "<leader>ms", function()
		run_cmd_in_float("make smoke", "make smoke")
	end, {
		desc = "Run make smoke in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>tt", function()
		run_cmd_in_float("uv run pytest", "pytest")
	end, {
		desc = "Run pytest in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>mr", function()
		run_cmd_in_float("make run", "make run")
	end, {
		desc = "Run make run in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>md", function()
		run_cmd_in_float("make debug", "make debug")
	end, {
		desc = "Run make debug in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>mt", function()
		run_cmd_in_float("make test", "make test")
	end, {
		desc = "Run make test in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "Markdown preview" })

	vim.keymap.set("n", "<leader>jc", function()
		run_cmd_in_float("just check", "just check")
	end, {
		desc = "Run just check in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>js", function()
		run_cmd_in_float("just smoke", "just smoke")
	end, {
		desc = "Run just smoke in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>jr", function()
		run_cmd_in_float("just run", "just run")
	end, {
		desc = "Run just run in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>jd", function()
		run_cmd_in_float("just debug", "just debug")
	end, {
		desc = "Run just debug in floating terminal",
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader>jt", function()
		run_cmd_in_float("just test", "just test")
	end, {
		desc = "Run just test in floating terminal",
		noremap = true,
		silent = true,
	})

	-- global typos (apply everywhere)
	vim.cmd("iabbrev teh the")
	vim.cmd("iabbrev lenght length")
	vim.cmd("iabbrev widht width")
	vim.cmd("iabbrev heigth height")

	-- python-specific (only in .py files)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		callback = function()
			local abbrevs = {
				-- typos
				improt = "import",
				pritn = "print",
				reutrn = "return",
				retunr = "return",
				flase = "False",
				ture = "True",
				noen = "None",
				slef = "self",
				lmabda = "lambda",
				yeild = "yield",
				fitler = "filter",

				-- boilerplate
				ifmain = "if __name__ == '__main__':",
				impnp = "import numpy as np",
				imppd = "import pandas as pd",
				imppath = "from pathlib import Path",
				impdc = "from dataclasses import dataclass, field",
				imppyt = "import pytest",
				bkpt = "breakpoint()",

				-- comments
				todo = "# TODO:",
				fixme = "# FIXME:",
				hack = "# HACK:",
				note = "# NOTE:",

				-- case fixes (Python is case-sensitive, these are common)
				["true"] = "True",
				["false"] = "False",

				-- common class name typos
				Basemodel = "BaseModel",
				basemodel = "BaseModel",
				Basmodel = "BaseModel",
				dataframe = "DataFrame",
				Dataframe = "DataFrame",
				dataFrame = "DataFrame",
				serie = "Series",

				-- stdlib / builtins
				Datetime = "datetime",
				dictionnary = "dictionary",
				valueerror = "ValueError",
				typeerror = "TypeError",
				keyerror = "KeyError",
				indexerror = "IndexError",
				filenotfounderror = "FileNotFoundError",
				notimplementederror = "NotImplementedError",
				runtimeerror = "RuntimeError",
			}

			for lhs, rhs in pairs(abbrevs) do
				vim.cmd("iabbrev <buffer> " .. lhs .. " " .. rhs)
			end
		end,
	})
end
