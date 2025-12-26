local M = {}
local utils = require("pangu.utils")

M.TokenType = {
	CHINESE = 1,
	ENGLISH = 2,
	DIGIT = 3,
	WHITESPACE = 4,
	PUNCTUATION = 5,
	MARKDOWN_CODE = 6,
	MARKDOWN_EMPHASIS = 7, -- This covers *, **, ***, _, __, and ___
	MARKDOWN_LINK = 8,
	OTHER = 9,
}

-- TokenStream Class
local TokenStream = {}
TokenStream.__index = TokenStream

function TokenStream.new(tokens)
	return setmetatable({
		tokens = tokens,
		pos = 1,
		size = #tokens,
	}, TokenStream)
end

function TokenStream:current()
	return self.tokens[self.pos]
end

function TokenStream:peek(offset)
	offset = offset or 1
	local idx = self.pos + offset
	return self.tokens[idx]
end

function TokenStream:next()
	local t = self:current()
	self.pos = self.pos + 1
	return t
end

function TokenStream:is_eof()
	return self.pos > self.size
end

function TokenStream:peek_non_whitespace(direction)
	local step = direction or 1
	local i = self.pos + step
	while i >= 1 and i <= self.size do
		if self.tokens[i].type ~= M.TokenType.WHITESPACE then
			return self.tokens[i]
		end
		i = i + step
	end
	return nil
end

-- UTF-8 splitting logic to handle multi-byte characters
function M.split_utf8(text)
	local result = {}
	if not text or #text == 0 then
		return result
	end

	local i = 1
	while i <= #text do
		local byte = string.byte(text, i)
		local char_len = 1

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

function M.classify_token(token)
	if utils.is_whitespace(token) then
		return M.TokenType.WHITESPACE
	end

	-- MARKDOWN SYMBOLS: Check these before general Chinese/Punctuation
	if token == "`" then
		return M.TokenType.MARKDOWN_CODE
	end
	if token == "*" or token == "_" then
		return M.TokenType.MARKDOWN_EMPHASIS
	end
	if token == "[" or token == "]" or token == "(" or token == ")" then
		return M.TokenType.MARKDOWN_LINK
	end

	-- CHINESE: Matches Han characters
	if utils.is_chinese(token) then
		return M.TokenType.CHINESE
	end

	-- PUNCTUATION: Matches full-width and half-width marks
	if utils.is_punctuation(token) then
		return M.TokenType.PUNCTUATION
	end

	-- ALPHANUMERIC: Matches English and Digits
	if utils.is_english_or_digit(token) then
		return string.match(token, "%d") and M.TokenType.DIGIT or M.TokenType.ENGLISH
	end

	return M.TokenType.OTHER
end

function M.tokenize(text)
	local chars = M.split_utf8(text)
	local classified = {}
	for i, char in ipairs(chars) do
		classified[i] = {
			token = char,
			type = M.classify_token(char),
		}
	end
	return TokenStream.new(classified)
end

return M
