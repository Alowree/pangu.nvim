-- Configuration management for pangu.nvim

local M = {}

-- Default configuration
M.defaults = {
	-- Master enable/disable for the plugin
	enabled = true,
	-- Enable specific formatting rules
	enable_spacing = true, -- Add spaces between CJK and English/Digit
	add_space_between_cjk_and_english = true,
	add_space_between_cjk_and_digit = true,
	add_space_around_markdown = true, -- Space around inline code, bold, links

	enable_punct_convert = true, -- Convert English punctuation to Chinese
	enable_paren_convert = true, -- Convert English parentheses to Chinese
	enable_dedup_marks = true, -- Remove duplicate punctuation marks

	-- Autocommands
	enable_on_save = true, -- Format on file save
	file_patterns = { "*.md", "*.txt", "*.norg" },

	-- Quote conversion
	enable_quote_convert = true, -- Convert ASCII quotes to Chinese quotes in CJK contexts

	-- Code block handling
	skip_code_blocks = true, -- Skip formatting inside markdown code blocks (``` or ````)
}

-- Current configuration
M.config = vim.deepcopy(M.defaults)

-- Setup function
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.defaults, opts)
	return M.config
end

-- Get configuration value (backwards-compatible)
function M.get(key)
	if M.config[key] ~= nil then
		return M.config[key]
	end
	if M.config.spacing and M.config.spacing[key] ~= nil then
		return M.config.spacing[key]
	end
	return nil
end

-- Set configuration value (backwards-compatible)
function M.set(key, value)
	if M.config[key] ~= nil then
		M.config[key] = value
		return
	end
	if M.config.spacing and M.config.spacing[key] ~= nil then
		M.config.spacing[key] = value
		return
	end
	-- Fallback: set at top-level
	M.config[key] = value
end

return M
