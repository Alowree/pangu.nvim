if vim.g.loaded_pangu then
	return
end
vim.g.loaded_pangu = true

local pangu = require("pangu")

-- Setup with default config
pangu.setup()

-- Format entire buffer
vim.api.nvim_create_user_command("Pangu", function()
	pangu.format_buffer()
end, { desc = "Format entire buffer with pangu.nvim" })

-- Format current line
vim.api.nvim_create_user_command("PanguLine", function()
	local line = vim.fn.line(".")
	pangu.format_range(line, line)
end, { desc = "Format current line with pangu.nvim" })

-- Format selection (visual mode)
vim.api.nvim_create_user_command("PanguSelection", function()
	-- Using 'range' attribute allows Neovim to pass line1 and line2 directly
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	pangu.format_range(start_line, end_line)
end, { range = true, desc = "Format selected range with pangu.nvim" })

vim.api.nvim_create_user_command("PanguToggle", function()
	local is_enabled = require("pangu").toggle()

	-- Force the statusline to update immediately
	vim.cmd("redrawstatus")

	local status = is_enabled and "enabled" or "disabled"
	vim.notify("pangu.nvim: " .. status, vim.log.levels.INFO, { title = "Pangu" })
end, { desc = "Toggle pangu.nvim auto-formatting" })

-- Version and State management
vim.api.nvim_create_user_command("PanguVersion", function()
	print("pangu.nvim v" .. pangu.version)
end, { desc = "Show pangu.nvim version" })

vim.api.nvim_create_user_command("PanguEnable", function()
	pangu.config.set("enabled", true)
	print("pangu.nvim: enabled")
end, { desc = "Enable pangu.nvim" })

vim.api.nvim_create_user_command("PanguDisable", function()
	pangu.config.set("enabled", false)
	print("pangu.nvim: disabled")
end, { desc = "Disable pangu.nvim" })

-- Automatically format on save if enabled in config
local augroup = vim.api.nvim_create_augroup("PanguAutocmds", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	pattern = "*", -- Listen to all, filter inside for dynamic config support
	callback = function(args)
		local conf = require("pangu.config")

		-- 1. Check if global master toggle and auto-save are enabled
		if not conf.get("enabled") or not conf.get("enable_on_save") then
			return
		end

		-- 2. Validate file patterns table
		local patterns = conf.get("file_patterns")
		if type(patterns) ~= "table" then
			return
		end

		-- 3. Check if the current buffer's filename matches our patterns
		local path = vim.api.nvim_buf_get_name(args.buf)
		local matched = false

		for _, pat in ipairs(patterns) do
			-- Convert glob (*.md) to Lua regex (.*%.md$)
			local lua_pat = pat:gsub("%.", "%%."):gsub("%*", ".*") .. "$"
			if path:match(lua_pat) then
				matched = true
				break
			end
		end

		-- 4. Execute formatting on the specific buffer being saved
		if matched then
			pangu.format_buffer(args.buf)
		end
	end,
	desc = "Auto-format buffer with pangu.nvim on save",
})

vim.api.nvim_create_user_command("PanguIgnore", function(opts)
	if opts.range > 0 then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", true)
	end

	local start_line = opts.line1
	local end_line = opts.line2

	-- Get indentation of first line
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)
	local indent = (lines[1] or ""):match("^%s*") or ""

	-- Prepare tags
	local cms = vim.bo.commentstring == "" and "%s" or vim.bo.commentstring
	local format_str = cms:find("%%s") and cms or " %s "
	if not format_str:find(" %%s") then
		format_str = format_str:gsub("%%s", " %%s ")
	end

	local start_tag = indent .. string.format(format_str:gsub("%%s", "pangu-ignore-start"))
	local end_tag = indent .. string.format(format_str:gsub("%%s", "pangu-ignore-end"))

	-- Insert Bottom: blank line, tag, blank line (reverse order for stability)
	vim.api.nvim_buf_set_lines(0, end_line, end_line, false, { "", end_tag, "" })

	-- Insert Top: blank line, tag, blank line
	vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { "", start_tag, "" })

	vim.notify("pangu.nvim: range ignored with external padding", vim.log.levels.INFO)
end, { range = true, desc = "Wrap selection with padded pangu-ignore tags" })

vim.api.nvim_create_user_command("PanguIgnoreCleanup", function()
	local cur_line = vim.fn.line(".")
	local total_lines = vim.api.nvim_buf_line_count(0)

	local start_idx = nil
	local end_idx = nil

	-- 1. Search UPWARD for the start tag
	for i = cur_line, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
		if line:find("pangu%-ignore%-end") and i ~= cur_line then
			vim.notify("pangu.nvim: Found an end-tag above. Mismatched block.", vim.log.levels.ERROR)
			return
		end
		if line:find("pangu%-ignore%-start") then
			start_idx = i
			break
		end
	end

	-- 2. Search DOWNWARD for the end tag
	for i = cur_line, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
		if line:find("pangu%-ignore%-start") and i ~= cur_line then
			vim.notify("pangu.nvim: Found a start-tag below. Mismatched block.", vim.log.levels.ERROR)
			return
		end
		if line:find("pangu%-ignore%-end") then
			end_idx = i
			break
		end
	end

	if not (start_idx and end_idx) then
		vim.notify("pangu.nvim: Not inside a valid pangu-ignore block.", vim.log.levels.WARN)
		return
	end

	----------------------------------------------------------------------------
	-- 3. Padding Normalization Logic
	----------------------------------------------------------------------------
	local function is_blank(idx)
		if idx < 1 or idx > vim.api.nvim_buf_line_count(0) then
			return false
		end
		local line = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
		return line and line:match("^%s*$") ~= nil
	end

	-- Revised internal helper
	local function process_tag(idx)
		local above_blank = is_blank(idx - 1)
		local below_blank = is_blank(idx + 1)

		if above_blank and below_blank then
			-- Case 1: 3 blank lines total.
			-- Delete the tag line and the line ABOVE it.
			-- This leaves the "inner" blank line for the content.
			vim.api.nvim_buf_set_lines(0, idx - 2, idx, false, {})
		elseif above_blank or below_blank then
			-- Case 2: 2 blank lines total.
			-- Simply remove the tag line.
			vim.api.nvim_buf_set_lines(0, idx - 1, idx, false, {})
		else
			-- Case 3: 0 blank lines total.
			-- Replace tag string with an empty line.
			vim.api.nvim_buf_set_lines(0, idx - 1, idx, false, { "" })
		end
	end

	-- 4. Execute (End first to preserve Start index)
	process_tag(end_idx)
	process_tag(start_idx)

	vim.notify("pangu.nvim: Block cleaned and spacing normalized.", vim.log.levels.INFO)
end, { desc = "Clean ignore tags and normalize whitespace" })
