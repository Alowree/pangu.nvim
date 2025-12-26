local M = {}
local utils = require("pangu.utils")
local tokenizer = require("pangu.tokenizer")
local config = require("pangu.config")

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function is_cjk_content(token_obj)
	if not token_obj then
		return false
	end
	-- A token is "CJK Content" if it is a Chinese character
	-- BUT NOT a punctuation mark (like ，。！？)
	local token = token_obj.token
	return utils.is_chinese(token) and not utils.is_chinese_punctuation(token)
end

local function find_closing_token(stream, start_pos, close_token)
	local i = start_pos + 1
	while i <= stream.size do
		if stream.tokens[i].token == close_token then
			return i
		end
		i = i + 1
	end
	return nil
end

--------------------------------------------------------------------------------
-- Spacing Logic
--------------------------------------------------------------------------------

local function apply_content_spacing(text)
	local stream = tokenizer.tokenize(text)
	local out = {}
	local types = tokenizer.TokenType

	while not stream:is_eof() do
		local curr = stream:next()
		table.insert(out, curr.token)

		local next_token = stream:peek(0)
		if next_token and curr.type ~= types.WHITESPACE and next_token.type ~= types.WHITESPACE then
			local t1, t2 = curr.type, next_token.type
			-- Standard CJK <-> English/Digit spacing
			local is_cjk_boundary = (t1 == types.CHINESE and (t2 == types.ENGLISH or t2 == types.DIGIT))
				or (t2 == types.CHINESE and (t1 == types.ENGLISH or t1 == types.DIGIT))

			-- FIX: Handle English parentheses spacing when adjacent to English text
			if t1 == types.ENGLISH and next_token.token == "(" then
				is_cjk_boundary = true
			end

			if is_cjk_boundary then
				table.insert(out, " ")
			end
		end
	end
	return table.concat(out)
end

local function apply_markdown_spacing(text)
	local stream = tokenizer.tokenize(text)
	local out = {}
	local types = tokenizer.TokenType

	while not stream:is_eof() do
		local curr = stream:current()
		local close_idx = nil

		-- 1. Code Logic (supports `code` and ``code``)
		if curr.type == types.MARKDOWN_CODE then
			local fence_char = curr.token
			local fence_size = (stream:peek(1) and stream:peek(1).token == fence_char) and 2 or 1
			for j = stream.pos + fence_size, stream.size - (fence_size - 1) do
				local match = true
				for k = 0, fence_size - 1 do
					if stream.tokens[j + k].token ~= fence_char then
						match = false
						break
					end
				end
				if match then
					close_idx = j + (fence_size - 1)
					break
				end
			end

		-- 2. Bold/Italic/Mixed Logic (supports *, **, ***, _, __, ___)
		elseif curr.type == types.MARKDOWN_EMPHASIS or curr.type == types.MARKDOWN_BOLD then
			local marker = curr.token
			local fence_size = 1
			if stream:peek(1) and stream:peek(1).token == marker then
				fence_size = 2
				if stream:peek(2) and stream:peek(2).token == marker then
					fence_size = 3
				end
			end

			local start_search = stream.pos + fence_size
			for j = start_search, stream.size - (fence_size - 1) do
				local match = true
				for k = 0, fence_size - 1 do
					if stream.tokens[j + k].token ~= marker then
						match = false
						break
					end
				end
				-- Ensure the character AFTER the closing fence isn't the same marker
				if match then
					local after = stream.tokens[j + fence_size]
					if not (after and after.token == marker) then
						close_idx = j + (fence_size - 1)
						break
					end
				end
			end

		-- 3. Links [text](url)
		elseif curr.token == "[" then
			local end_br = find_closing_token(stream, stream.pos, "]")
			if
				end_br
				and stream:peek(end_br - stream.pos + 1)
				and stream:peek(end_br - stream.pos + 1).token == "("
			then
				close_idx = find_closing_token(stream, end_br + 1, ")")
			end
		end

		if close_idx then
			-- PADDING BEFORE: Look at the token exactly before the start of the block
			local prev = stream.tokens[stream.pos - 1]
			if is_cjk_content(prev) then
				table.insert(out, " ")
			end

			-- INSERT CONTENT
			for j = stream.pos, close_idx do
				table.insert(out, stream.tokens[j].token)
			end

			-- MOVE STREAM
			stream.pos = close_idx + 1

			-- PADDING AFTER: Look at the token exactly after the block
			local next_t = stream:current()
			if is_cjk_content(next_t) then
				table.insert(out, " ")
			end
		else
			table.insert(out, stream:next().token)
		end
	end
	return table.concat(out)
end

--------------------------------------------------------------------------------
-- Conversion Logic
--------------------------------------------------------------------------------

local function apply_conversions(text)
	local stream = tokenizer.tokenize(text)
	local out = {}
	local types = tokenizer.TokenType

	while not stream:is_eof() do
		local curr = stream:next()
		local token = curr.token
		local prev = stream:peek_non_whitespace(-2)

		if utils.punct_map[token] or token == "(" then
			local map = utils.punct_map[token] or utils.paren_map[token]
			if prev and (prev.type == types.CHINESE or utils.is_chinese_punctuation(prev.token)) then
				token = map
			end
		elseif token == "（" then
			if prev and (prev.type == types.ENGLISH or prev.type == types.DIGIT) then
				token = "("
			end
		elseif token == ")" or token == "）" then
			for j = #out, 1, -1 do
				if out[j] == "（" then
					token = "）"
					break
				elseif out[j] == "(" then
					token = ")"
					break
				end
			end
		end
		table.insert(out, token)
	end
	local result = table.concat(out)
	result = result:gsub("([%a%d])%(", "%1 (")
	return result
end

local function apply_quote_convert(text)
	local stream = tokenizer.tokenize(text)
	local n = stream.size

	for i = 1, n do
		local t = stream.tokens[i].token
		if utils.is_ascii_quote(t) then
			local k = nil
			for j = i + 1, n do
				if stream.tokens[j].token == t then
					k = j
					break
				end
			end
			if k then
				local has_cjk = false
				for j = i, k do
					if stream.tokens[j].type == tokenizer.TokenType.CHINESE then
						has_cjk = true
						break
					end
				end
				if has_cjk or is_cjk_content(stream.tokens[i - 1]) or is_cjk_content(stream.tokens[k + 1]) then
					if utils.quote_map and utils.quote_map[t] then
						stream.tokens[i].token = utils.quote_map[t].open
						stream.tokens[k].token = utils.quote_map[t].close
					end
				end
			end
		end
	end
	local out = {}
	for _, v in ipairs(stream.tokens) do
		table.insert(out, v.token)
	end
	return table.concat(out)
end

local function normalize_repeated_marks(text)
	local result = text
	for mark, _ in pairs(utils.dedup_chars) do
		local double = mark .. mark
		while result:find(double, 1, true) do
			result = result:gsub(double, mark)
		end
	end
	return result
end

--------------------------------------------------------------------------------
-- Main API
--------------------------------------------------------------------------------

function M.format(text)
	if not text or #text == 0 or config.get("enabled") == false then
		return text
	end

	if config.get("enable_spacing_basic") then
		text = apply_content_spacing(text)
		if config.get("enable_spacing_expanded") then
			text = apply_markdown_spacing(text)
		end
	end
	if config.get("enable_punct_convert") or config.get("enable_paren_convert") then
		text = apply_conversions(text)
	end
	if config.get("enable_quote_convert") then
		text = apply_quote_convert(text)
	end
	if config.get("enable_dedup_marks") then
		text = normalize_repeated_marks(text)
	end

	return text
end

local function is_ignore_directive(line)
	if not line then
		return nil
	end
	if line:find("pangu%-ignore%-start") then
		return "start"
	end
	if line:find("pangu%-ignore%-end") then
		return "end"
	end
	return nil
end

local function get_fence_info(line)
	if not line then
		return nil
	end
	local fence = line:match("^%s*(```+)")
	if fence then
		return #fence
	end
	return nil
end

function M.format_buffer(bufnr)
	bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
	local opening_fence_size = nil
	local manual_ignore = false
	local changed = false

	for i, line in ipairs(lines) do
		local directive = is_ignore_directive(line)
		local current_fence_size = get_fence_info(line)

		if directive == "start" then
			manual_ignore = true
		elseif directive == "end" then
			manual_ignore = false
		end

		if config.get("skip_code_blocks") then
			if not opening_fence_size then
				if current_fence_size then
					opening_fence_size = current_fence_size
				end
			else
				if current_fence_size and current_fence_size >= opening_fence_size then
					opening_fence_size = nil
				end
			end
		end

		local should_skip = (opening_fence_size ~= nil) or manual_ignore

		if not should_skip and not directive and not current_fence_size then
			local formatted = M.format(line)
			if formatted ~= line then
				lines[i] = formatted
				changed = true
			end
		end
	end

	if changed then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
	end
end

return M
