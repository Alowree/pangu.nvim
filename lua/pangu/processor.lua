-- Core text processing logic
-- Implements all formatting transformations

local M = {}
local utils = require("pangu.utils")
local tokenizer = require("pangu.tokenizer")
local config = require("pangu.config")

-- Add whitespace between CJK and English/Digits
local function add_cjk_spacing(text)
	local result = {}
	local tokens = tokenizer.tokenize(text)
	
	for i = 1, #tokens do
		table.insert(result, tokens[i].token)
		
		-- Look ahead to next non-whitespace token
		if i < #tokens then
			local j = i + 1
			while j <= #tokens and tokens[j].type == tokenizer.TokenType.WHITESPACE do
				j = j + 1
			end
			
			if j <= #tokens then
				local curr_type = tokens[i].type
				local next_type = tokens[j].type
				
				-- Add space between CJK and English/Digit (if not already whitespace)
				if tokens[i + 1].type ~= tokenizer.TokenType.WHITESPACE then
					if (curr_type == tokenizer.TokenType.CHINESE and
						(next_type == tokenizer.TokenType.ENGLISH or next_type == tokenizer.TokenType.DIGIT)) or
					   (curr_type == tokenizer.TokenType.ENGLISH and next_type == tokenizer.TokenType.CHINESE) or
					   (curr_type == tokenizer.TokenType.DIGIT and next_type == tokenizer.TokenType.CHINESE) then
						table.insert(result, " ")
					end
				end
			end
		end
	end
	
	return table.concat(result)
end

-- Convert English punctuation to Chinese equivalents after CJK characters
local function convert_punctuation(text)
	local result = {}
	local tokens = tokenizer.tokenize(text)
	
	for i = 1, #tokens do
		local token = tokens[i].token
		
		-- Convert punctuation after Chinese character
		if utils.punct_map[token] and i > 1 then
			local prev_token = tokens[i - 1]
			if prev_token.type == tokenizer.TokenType.CHINESE or
			   utils.is_chinese_punctuation(prev_token.token) then
				table.insert(result, utils.punct_map[token])
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
	-- Find () pairs around Chinese characters
	local result = text
	
	-- Look for pattern: Chinese ( ... ) Chinese
	-- Convert ( to （ and ) to ）
	result = string.gsub(result, "([^\(]*)(中文)([^\)]*)(%()([^\)]*)(%))([^\(]*)", function(prefix, cjk1, between, open, inner, close, suffix)
		return prefix .. cjk1 .. between .. "（" .. inner .. "）" .. suffix
	end)
	
	-- More robust approach: iterate through text
	local tokens = tokenizer.tokenize(result)
	local processed = {}
	
	for i = 1, #tokens do
		local token = tokens[i].token
		
		if token == "(" and i > 1 and tokens[i - 1].type == tokenizer.TokenType.CHINESE then
			table.insert(processed, "（")
		elseif token == ")" and i > 1 then
			-- Check if there was an opening （
			local has_open = false
			for j = i - 1, 1, -1 do
				if tokens[j].token == "（" then
					has_open = true
					break
				elseif tokens[j].token == "(" then
					has_open = true
					break
				end
			end
			if has_open then
				table.insert(processed, "）")
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
	
	-- Convert repeated 。 to …… (six dots)
	result = string.gsub(result, "。{2,}", "……")
	
	-- Truncate repeated ？ to single ?
	result = string.gsub(result, "？{2,}", "？")
	
	-- Truncate repeated ！ to single !
	result = string.gsub(result, "！{2,}", "！")
	
	-- Truncate other repeated marks to single
	for mark, _ in pairs(utils.dedup_chars) do
		if mark ~= "。" and mark ~= "？" and mark ~= "！" then
			local escaped = string.gsub(mark, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
			result = string.gsub(result, escaped .. "{2,}", mark)
		end
	end
	
	return result
end

-- Main formatting function
-- Applies all transformations in sequence
function M.format(text)
	if not text or #text == 0 then
		return text
	end
	
	-- Apply transformations based on config
	if config.get("enable_spacing") then
		text = add_cjk_spacing(text)
	end
	
	if config.get("enable_punct_convert") then
		text = convert_punctuation(text)
	end
	
	if config.get("enable_paren_convert") then
		text = convert_parentheses(text)
	end
	
	if config.get("enable_dedup_marks") then
		text = normalize_repeated_marks(text)
	end
	
	return text
end

-- Format a buffer or range
function M.format_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
	
	for i, line in ipairs(lines) do
		lines[i] = M.format(line)
	end
	
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
end

-- Format a specific range
function M.format_range(bufnr, start_line, end_line)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, true)
	
	for i, line in ipairs(lines) do
		lines[i] = M.format(line)
	end
	
	vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, true, lines)
end

return M
