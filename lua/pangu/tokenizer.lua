-- Tokenizer for text processing
-- Handles UTF-8 aware token splitting and classification

local M = {}
local utils = require("pangu.utils")

-- Token types
M.TokenType = {
	CHINESE = 1,
	ENGLISH = 2,
	DIGIT = 3,
	WHITESPACE = 4,
	PUNCTUATION = 5,
	MARKDOWN_CODE = 6,      -- backticks `
	MARKDOWN_BOLD = 7,       -- ** or __
	MARKDOWN_LINK = 8,       -- [text](url)
	OTHER = 9,
}

-- Split string into UTF-8 characters
function M.split_utf8(text)
	local result = {}
	if not text or #text == 0 then
		return result
	end
	
	local i = 1
	while i <= #text do
		local byte = string.byte(text, i)
		local char_len = 1
		
		-- Determine UTF-8 character length
		if byte < 0x80 then
			char_len = 1
		elseif byte < 0xE0 then
			char_len = 2
		elseif byte < 0xF0 then
			char_len = 3
		else
			char_len = 4
		end
		
		if i + char_len - 1 <= #text then
			table.insert(result, string.sub(text, i, i + char_len - 1))
		end
		i = i + char_len
	end
	
	return result
end

-- Classify a single character/token
function M.classify_token(token)
	if not token or #token == 0 then
		return M.TokenType.OTHER
	end
	
	if utils.is_whitespace(token) then
		return M.TokenType.WHITESPACE
	end
	
	if utils.is_chinese(token) then
		return M.TokenType.CHINESE
	end
	
	if utils.is_english_or_digit(token) then
		if string.match(token, "[0-9]") then
			return M.TokenType.DIGIT
		else
			return M.TokenType.ENGLISH
		end
	end
	
	if token == "`" then
		return M.TokenType.MARKDOWN_CODE
	end
	
	if token == "*" or token == "_" then
		return M.TokenType.MARKDOWN_BOLD
	end
	
	if token == "[" or token == "]" or token == "(" or token == ")" then
		return M.TokenType.MARKDOWN_LINK
	end
	
	return M.TokenType.OTHER
end

-- Tokenize text and return both tokens and their types
function M.tokenize(text)
	local tokens = M.split_utf8(text)
	local classified = {}
	
	for i, token in ipairs(tokens) do
		classified[i] = {
			token = token,
			type = M.classify_token(token),
		}
	end
	
	return classified
end

return M
