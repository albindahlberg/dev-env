local ts_kinds = {
	class_declaration = true,
	abstract_class_declaration = true,
	interface_declaration = true,
	type_alias_declaration = true,
	enum_declaration = true,
}
local ts = { kinds = ts_kinds, body = "(method_definition body: (statement_block) @body)", stub = "{ ... }" }

local langs = {
	python = {
		kinds = { class_definition = true },
		body = "(function_definition body: (block) @body)",
		stub = "...",
	},
	typescript = ts,
	tsx = ts,
}

local wrappers = { decorated_definition = true, export_statement = true }

local peek_win

local function close()
	local was_open = peek_win and vim.api.nvim_win_is_valid(peek_win)
	if was_open then
		pcall(vim.api.nvim_win_close, peek_win, true)
	end
	peek_win = nil
	return was_open
end

local function is_model(node, kinds)
	if kinds[node:type()] then
		return true
	end
	if wrappers[node:type()] then
		for child in node:iter_children() do
			if kinds[child:type()] then
				return true
			end
		end
	end
end

local function render(node, query, spec, lines)
	local sr, _, er = node:range()
	local out = vim.list_slice(lines, sr + 1, er + 1)
	local cuts = {}
	for _, body in query:iter_captures(node, 0) do
		local bsr, bsc, ber, bec = body:range()
		local own_line = bsr ~= ber or body:prev_sibling():end_() < bsr
		if own_line and (#cuts == 0 or bsr > cuts[#cuts][3]) then
			table.insert(cuts, { bsr, bsc, ber, bec })
		end
	end
	for i = #cuts, 1, -1 do
		local c = cuts[i]
		local a, z = c[1] - sr + 1, c[3] - sr + 1
		local line = out[a]:sub(1, c[2]) .. spec.stub .. out[z]:sub(c[4] + 1)
		for _ = a, z do
			table.remove(out, a)
		end
		table.insert(out, a, line)
	end
	return out
end

local function toggle()
	if close() then
		return
	end
	local ok, parser = pcall(vim.treesitter.get_parser, 0)
	local spec = ok and parser and langs[parser:lang()]
	if not spec then
		return vim.notify("No model peek for this filetype")
	end
	local query = vim.treesitter.query.parse(parser:lang(), spec.body)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local out, count = {}, 0
	for node in parser:parse()[1]:root():iter_children() do
		if is_model(node, spec.kinds) then
			if count > 0 then
				table.insert(out, "")
			end
			vim.list_extend(out, render(node, query, spec, lines))
			count = count + 1
		end
	end
	if count == 0 then
		return vim.notify("No models in this file")
	end

	local src = vim.api.nvim_get_current_buf()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
	vim.treesitter.start(buf, parser:lang())
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(src), ":t")
	pcall(vim.api.nvim_buf_set_name, buf, "models: " .. name .. " · " .. count)
	for _, key in ipairs({ "q", "<leader>H" }) do
		vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
	end

	peek_win = vim.api.nvim_open_win(buf, false, { split = "right", win = 0 })
	local wo = vim.wo[peek_win]
	wo.number, wo.relativenumber, wo.signcolumn, wo.wrap = false, false, "no", false
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", "typescript", "typescriptreact" },
	callback = function(args)
		vim.keymap.set("n", "<leader>H", toggle, { buffer = args.buf, desc = "Toggle models in file" })
	end,
})
