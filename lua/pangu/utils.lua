-- Utility functions for character detection and conversion
local M = {}

-- Check if character is Chinese (CJK)
function M.is_chinese(char)
	if not char or #char == 0 then
		return false
	end
	local code
	if utf8 and utf8.codepoint then
		code = utf8.codepoint(char)
	else
		code = vim.fn.char2nr(char)
	end
	if not code then
		return false
	end
	return (code >= 0x4E00 and code <= 0x9FFF)
		or (code >= 0xF900 and code <= 0xFAFF)
		or (code >= 0x3400 and code <= 0x4DBF)
end

-- Check if character is English letter or digit
function M.is_english_or_digit(char)
	if not char or #char == 0 then
		return false
	end
	return string.match(char, "[a-zA-Z0-9]") ~= nil
end

function M.is_whitespace(char)
	if not char or #char == 0 then
		return false
	end
	return string.match(char, "%s") ~= nil
end

-- NEW: Check if character is English Punctuation
function M.is_english_punctuation(char)
	if not char or #char == 0 then
		return false
	end
	-- Standard ASCII punctuation set
	return string.match(char, "[%!%\"%#%$%%%&%'%(%)%*%+%,%-%%.%/%:% animal %;%<%=%>%?%@%[%\\%]%^%_%`%%{%|%}%~]") ~= nil
end

-- Check if character is Chinese punctuation
function M.is_chinese_punctuation(char)
	if not char or #char == 0 then
		return false
	end
	local chinese_punct = {
		["。"] = true,
		["，"] = true,
		["、"] = true,
		["；"] = true,
		["："] = true,
		["？"] = true,
		["！"] = true,
		["（"] = true,
		["）"] = true,
		["『"] = true,
		["』"] = true,
		["「"] = true,
		["」"] = true,
		["〖"] = true,
		["〗"] = true,
		["《"] = true,
		["》"] = true,
		["“"] = true,
		["”"] = true,
		["‘"] = true,
		["’"] = true,
	}
	return chinese_punct[char] ~= nil
end

-- Helper to check ANY punctuation
function M.is_punctuation(char)
	return M.is_english_punctuation(char) or M.is_chinese_punctuation(char)
end

M.quote_map = {
	['"'] = { open = "“", close = "”" },
	["'"] = { open = "‘", close = "’" },
}

function M.is_ascii_quote(char)
	return char == '"' or char == "'"
end

-- Mappings (Keep these as they were)
M.punct_map =
	{ [","] = "，", ["\\"] = "、", ["."] = "。", [":"] = "：", [";"] = "；", ["?"] = "？", ["!"] = "！" }
M.paren_map = { ["("] = "（", [")"] = "）" }
M.dedup_chars =
	{ ["？"] = true, ["！"] = true, ["。"] = true, ["，"] = true, ["；"] = true, ["："] = true, ["、"] = true }
-- ... (rest of quote maps remain the same)

return M
