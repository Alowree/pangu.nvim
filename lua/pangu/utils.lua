-- Utility functions for character detection and conversion

local M = {}

-- Check if character is Chinese (CJK)
function M.is_chinese(char)
	if not char or #char == 0 then
		return false
	end
	local code = utf8.codepoint(char)
	if not code then
		return false
	end
	-- CJK Unified Ideographs: 0x4E00-0x9FFF
	-- CJK Compatibility Ideographs: 0xF900-0xFAFF
	-- CJK Unified Ideographs Extension A: 0x3400-0x4DBF
	return (code >= 0x4E00 and code <= 0x9FFF) or
		   (code >= 0xF900 and code <= 0xFAFF) or
		   (code >= 0x3400 and code <= 0x4DBF)
end

-- Check if character is English letter or digit
function M.is_english_or_digit(char)
	if not char or #char == 0 then
		return false
	end
	return string.match(char, "[a-zA-Z0-9]") ~= nil
end

-- Check if character is whitespace
function M.is_whitespace(char)
	if not char or #char == 0 then
		return false
	end
	return string.match(char, "%s") ~= nil
end

-- Check if character is Chinese punctuation
function M.is_chinese_punctuation(char)
	if not char or #char == 0 then
		return false
	end
	local chinese_punct = {
		["。"] = true, ["，"] = true, ["、"] = true, ["；"] = true,
		["："] = true, ["？"] = true, ["！"] = true, ["（"] = true,
		["）"] = true, ["『"] = true, ["』"] = true, ["〖"] = true,
		["〗"] = true, ["《"] = true, ["》"] = true, [""""] = true,
	}
	return chinese_punct[char] ~= nil
end

-- Punctuation mapping: English to Chinese
M.punct_map = {
	[","] = "，",
	["\\"] = "、",
	["."] = "。",
	[":"] = "：",
	[";"] = "；",
	["?"] = "？",
	["!"] = "！",
}

-- Parenthesis mapping: English to Chinese
M.paren_map = {
	["("] = "（",
	[")"] = "）",
}

-- Characters that should be deduplicated
M.dedup_chars = {
	["？"] = true, ["！"] = true, ["。"] = true, ["，"] = true,
	["；"] = true, ["："] = true, ["、"] = true, ["""] = true,
	["『"] = true, ["』"] = true, ["〖"] = true, ["〗"] = true,
	["《"] = true, ["》"] = true,
}

return M
