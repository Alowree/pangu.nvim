-- Core text processing logic
-- Implements all formatting transformations

local M = {}
local utils = require("pangu.utils")
local tokenizer = require("pangu.tokenizer")
local config = require("pangu.config")

-- Add space between CJK and English words
local function add_space_between_cjk_and_english(text)
	local result = {}
	local tokens = tokenizer.tokenize(text)

	local function next_non_ws(i)
		local j = i + 1
		while j <= #tokens and tokens[j].type == tokenizer.TokenType.WHITESPACE do
			j = j + 1
		end
		return j
	end

	for i = 1, #tokens do
		table.insert(result, tokens[i].token)

		if i < #tokens then
			local j = next_non_ws(i)
			if j <= #tokens then
				local curr_type = tokens[i].type
				local next_type = tokens[j].type

				if tokens[i + 1].type ~= tokenizer.TokenType.WHITESPACE then
					if
						(curr_type == tokenizer.TokenType.CHINESE and next_type == tokenizer.TokenType.ENGLISH)
						or (curr_type == tokenizer.TokenType.ENGLISH and next_type == tokenizer.TokenType.CHINESE)
					then
						table.insert(result, " ")
					end
				end
			end
		end
	end

	return table.concat(result)
end

-- Add space between CJK and digits
local function add_space_between_cjk_and_digit(text)
	local result = {}
	local tokens = tokenizer.tokenize(text)

	local function next_non_ws(i)
		local j = i + 1
		while j <= #tokens and tokens[j].type == tokenizer.TokenType.WHITESPACE do
			j = j + 1
		end
		return j
	end

	for i = 1, #tokens do
		table.insert(result, tokens[i].token)

		if i < #tokens then
			local j = next_non_ws(i)
			if j <= #tokens then
				local curr_type = tokens[i].type
				local next_type = tokens[j].type

				if tokens[i + 1].type ~= tokenizer.TokenType.WHITESPACE then
					if
						(curr_type == tokenizer.TokenType.CHINESE and next_type == tokenizer.TokenType.DIGIT)
						or (curr_type == tokenizer.TokenType.DIGIT and next_type == tokenizer.TokenType.CHINESE)
					then
						table.insert(result, " ")
					end
				end
			end
		end
	end

	return table.concat(result)
end

-- Add spaces between CJK and Markdown constructs (inline code, bold markers, links)
local function add_space_around_markdown(text)
	-- Token-based approach: detect markdown units (`code`, **bold**, [link](url))
	-- and add spaces only on the Chinese-character side (not on Chinese punctuation).
	local tokens = tokenizer.tokenize(text)
	local out = {}
	local i = 1
	while i <= #tokens do
		local t = tokens[i]

		-- Inline code delimited by backticks
		if t.token == "`" then
			local k = nil
			for j = i + 1, #tokens do
				if tokens[j].token == "`" then
					k = j
					break
				end
			end
			if not k then
				table.insert(out, t.token)
				i = i + 1
			else
				-- prev non-ws
				local p = i - 1
				while p >= 1 and tokens[p].type == tokenizer.TokenType.WHITESPACE do
					p = p - 1
				end
				-- next non-ws
				local q = k + 1
				while q <= #tokens and tokens[q].type == tokenizer.TokenType.WHITESPACE do
					q = q + 1
				end

				if p >= 1 and tokens[p].type == tokenizer.TokenType.CHINESE and not utils.is_chinese_punctuation(tokens[p].token) then
					if #out > 0 and out[#out] ~= " " then
						table.insert(out, " ")
					end
				end

				for j = i, k do
					table.insert(out, tokens[j].token)
				end

				if q <= #tokens and tokens[q].type == tokenizer.TokenType.CHINESE and not utils.is_chinese_punctuation(tokens[q].token) then
					table.insert(out, " ")
				end

				i = k + 1
			end

		-- Bold markers **...** (supporting ** only)
		elseif t.token == "*" and tokens[i + 1] and tokens[i + 1].token == "*" then
			local start = i
			local k = nil
			for j = i + 2, #tokens - 1 do
				if tokens[j].token == "*" and tokens[j + 1] and tokens[j + 1].token == "*" then
					k = j + 1
					break
				end
			end
			if not k then
				table.insert(out, t.token)
				i = i + 1
			else
				local p = start - 1
				while p >= 1 and tokens[p].type == tokenizer.TokenType.WHITESPACE do
					p = p - 1
				end
				local q = k + 1
				while q <= #tokens and tokens[q].type == tokenizer.TokenType.WHITESPACE do
					q = q + 1
				end

				if p >= 1 and tokens[p].type == tokenizer.TokenType.CHINESE and not utils.is_chinese_punctuation(tokens[p].token) then
					if #out > 0 and out[#out] ~= " " then
						table.insert(out, " ")
					end
				end

				for j = start, k do
					table.insert(out, tokens[j].token)
				end

				if q <= #tokens and tokens[q].type == tokenizer.TokenType.CHINESE and not utils.is_chinese_punctuation(tokens[q].token) then
					table.insert(out, " ")
				end

				i = k + 1
			end

		-- Links [text](url)
		elseif t.token == "[" then
			local end_br = nil
			for j = i + 1, #tokens do
				if tokens[j].token == "]" then
					end_br = j
					break
				end
			end
			if end_br and tokens[end_br + 1] and tokens[end_br + 1].token == "(" then
				local close_paren = nil
				for j = end_br + 2, #tokens do
					if tokens[j].token == ")" then
						close_paren = j
						break
					end
				end
				if close_paren then
					local p = i - 1
					while p >= 1 and tokens[p].type == tokenizer.TokenType.WHITESPACE do
						p = p - 1
					end
					local q = close_paren + 1
					while q <= #tokens and tokens[q].type == tokenizer.TokenType.WHITESPACE do
						q = q + 1
					end

					if p >= 1 and tokens[p].type == tokenizer.TokenType.CHINESE and not utils.is_chinese_punctuation(tokens[p].token) then
						if #out > 0 and out[#out] ~= " " then
							table.insert(out, " ")
						end
					end

					for j = i, close_paren do
						table.insert(out, tokens[j].token)
					end

					if q <= #tokens and tokens[q].type == tokenizer.TokenType.CHINESE and not utils.is_chinese_punctuation(tokens[q].token) then
						table.insert(out, " ")
					end

					i = close_paren + 1
				else
					table.insert(out, t.token)
					i = i + 1
				end
			else
				table.insert(out, t.token)
				i = i + 1
			end

		else
			table.insert(out, t.token)
			i = i + 1
		end
	end

	local s = table.concat(out)
	s = s:gsub("%s%s+", " ")
	return s
end

-- Convert English punctuation to Chinese equivalents when preceded by CJK
local function convert_punctuation(text)
	local result = {}
	local tokens = tokenizer.tokenize(text)

	for i = 1, #tokens do
		local token = tokens[i].token
		-- English punctuation -> Chinese when preceded by CJK
		if utils.punct_map[token] then
			-- Look back for previous non-whitespace token
			local prev_idx = i - 1
			while prev_idx >= 1 and tokens[prev_idx].type == tokenizer.TokenType.WHITESPACE do
				prev_idx = prev_idx - 1
			end

			if prev_idx >= 1 then
				local prev_token = tokens[prev_idx]
				if prev_token.type == tokenizer.TokenType.CHINESE or utils.is_chinese_punctuation(prev_token.token) then
					table.insert(result, utils.punct_map[token])
				else
					table.insert(result, token)
				end
			else
				table.insert(result, token)
			end
		else
			table.insert(result, token)
		end
	end

	return table.concat(result)
end

-- Convert English parentheses to Chinese around CJK characters
local function convert_parentheses(text)
	local tokens = tokenizer.tokenize(text)
	local processed = {}
	local open_converted = {} -- map of original open index -> converted char

	for i = 1, #tokens do
		local token = tokens[i].token

		-- Opening English '(' -> convert to Chinese '（' if preceded by CJK
		if token == "(" then
			local prev = i - 1
			while prev >= 1 and tokens[prev].type == tokenizer.TokenType.WHITESPACE do
				prev = prev - 1
			end
			if prev >= 1 and tokens[prev].type == tokenizer.TokenType.CHINESE then
				table.insert(processed, "（")
				open_converted[i] = "（"
			else
				table.insert(processed, token)
			end

		-- Opening Chinese '（' -> convert to English '(' if preceded by English/Digit
		elseif token == "（" then
			local prev = i - 1
			while prev >= 1 and tokens[prev].type == tokenizer.TokenType.WHITESPACE do
				prev = prev - 1
			end
			if
				prev >= 1
				and (tokens[prev].type == tokenizer.TokenType.ENGLISH or tokens[prev].type == tokenizer.TokenType.DIGIT)
			then
				table.insert(processed, "(")
				open_converted[i] = "("
			else
				table.insert(processed, token)
			end

		-- Closing paren: choose matching counterpart if the opening was converted
		elseif token == ")" or token == "）" then
			-- find matching opening in original tokens
			local matched = nil
			for j = i - 1, 1, -1 do
				if tokens[j].token == "(" or tokens[j].token == "（" then
					matched = j
					break
				end
			end
			if matched and open_converted[matched] then
				if open_converted[matched] == "（" then
					table.insert(processed, "）")
				else
					table.insert(processed, ")")
				end
			else
				table.insert(processed, token)
			end
		else
			table.insert(processed, token)
		end
	end

	return table.concat(processed)
end

-- Remove/normalize repeated punctuation marks
local function normalize_repeated_marks(text)
	local result = text

	-- Truncate repeated 。 to single 。
	while result:match("。。") do
		result = result:gsub("。。+", "。", 1)
	end

	-- Truncate repeated ？ to single ?
	while result:match("？？") do
		result = result:gsub("？？+", "？", 1)
	end

	-- Truncate repeated ！ to single !
	while result:match("！！") do
		result = result:gsub("！！+", "！", 1)
	end

	-- Truncate other repeated marks to single
	for mark, _ in pairs(utils.dedup_chars) do
		if mark ~= "。" and mark ~= "？" and mark ~= "！" then
			-- Use a simpler approach: match the character followed by itself one or more times
			local pattern = mark .. mark .. "+"
			while result:match(mark .. mark) do
				result = result:gsub(pattern, mark, 1)
			end
		end
	end

	return result
end

-- Convert ASCII quotes to Chinese quotes when used in CJK contexts
local function convert_quotes(text)
	local tokens = tokenizer.tokenize(text)
	local n = #tokens

	local function prev_non_ws(i)
		for p = i - 1, 1, -1 do
			if tokens[p].type ~= tokenizer.TokenType.WHITESPACE then
				return p
			end
		end
		return nil
	end

	local function next_non_ws(i)
		for q = i + 1, n do
			if tokens[q].type ~= tokenizer.TokenType.WHITESPACE then
				return q
			end
		end
		return nil
	end

	local i = 1
	while i <= n do
		local t = tokens[i].token
		if utils.is_ascii_quote(t) then
			-- Find matching closing quote of the same type
			local k = nil
			for j = i + 1, n do
				if tokens[j].token == t then
					k = j
					break
				end
			end
			if k then
				-- Check if there's CJK inside the quotes or adjacent
				local has_cjk_inside = false
				for j = i + 1, k - 1 do
					if tokens[j].type == tokenizer.TokenType.CHINESE then
						has_cjk_inside = true
						break
					end
				end
				local p = prev_non_ws(i)
				local q = next_non_ws(k)
				local around_cjk = (p and tokens[p].type == tokenizer.TokenType.CHINESE)
					or (q and tokens[q].type == tokenizer.TokenType.CHINESE)

				-- Convert ASCII quotes to Chinese quotes if CJK context detected
				if has_cjk_inside or around_cjk then
					local mapping = utils.quote_map[t]
					if mapping then
						tokens[i].token = mapping.open
						tokens[k].token = mapping.close
					end
				end
				i = k + 1
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end

	local out = {}
	for _, v in ipairs(tokens) do
		table.insert(out, v.token)
	end
	return table.concat(out)
end

-- Main formatting function
-- Applies all transformations in sequence
function M.format(text)
	if not text or #text == 0 then
		return text
	end

	-- Apply transformations based on config
	if config.get("enable_spacing") then
		-- Apply fine-grained spacing rules
		if config.get("add_space_between_cjk_and_english") then
			text = add_space_between_cjk_and_english(text)
		end
		if config.get("add_space_between_cjk_and_digit") then
			text = add_space_between_cjk_and_digit(text)
		end
		if config.get("add_space_around_markdown") then
			text = add_space_around_markdown(text)
		end
	end

	if config.get("enable_punct_convert") then
		text = convert_punctuation(text)
	end

	if config.get("enable_paren_convert") then
		text = convert_parentheses(text)
	end

	if config.get("enable_quote_convert") then
		text = convert_quotes(text)
	end

	if config.get("enable_dedup_marks") then
		text = normalize_repeated_marks(text)
	end

	return text
end

-- Check if a line is a code block fence (``` or ````)
-- Lua patterns don't support {3,} quantifiers, so match 3+ backticks as ```*
local function is_code_block_fence(line)
	return line:match("^%s*`%`%`%`*") ~= nil
end

-- Format a buffer or range
function M.format_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

	local in_code_block = false
	for i, line in ipairs(lines) do
		-- Check if this line is a code block fence
		if line:match("^%s*`{3,}") then
			-- Always add fence line as-is
			-- Toggle code block state only if skip_code_blocks is enabled
			if config.get("skip_code_blocks") then
				in_code_block = not in_code_block
			end
		elseif in_code_block and config.get("skip_code_blocks") then
			-- Inside code block and skip is enabled: keep as-is
			-- Don't format
		else
			-- Outside code block or skip disabled: format
			lines[i] = M.format(line)
		end
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
end

-- Format a specific range
function M.format_range(bufnr, start_line, end_line)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	-- Get all lines to track code block state from the beginning
	local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

	-- Determine code block state at start of range
	local in_code_block = false
	for i = 1, start_line - 1 do
		if config.get("skip_code_blocks") and is_code_block_fence(all_lines[i]) then
			in_code_block = not in_code_block
		end
	end

	-- Get lines in range
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, true)

	-- Format range lines, tracking code block state
	for i, line in ipairs(lines) do
		local is_fence = config.get("skip_code_blocks") and is_code_block_fence(line)

		if is_fence then
			in_code_block = not in_code_block
		end

		-- Don't format fence lines or lines inside code blocks (when skip enabled)
		if not (is_fence or (config.get("skip_code_blocks") and in_code_block)) then
			lines[i] = M.format(line)
		end
	end

	vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, true, lines)
end

return M
