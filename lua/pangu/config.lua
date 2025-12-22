-- Configuration management for pangu.nvim

local M = {}

-- Default configuration
M.defaults = {
	-- Enable specific formatting rules
	enable_spacing = true,           -- Add spaces between CJK and English/Digit
	enable_punct_convert = true,     -- Convert English punctuation to Chinese
	enable_paren_convert = true,     -- Convert English parentheses to Chinese
	enable_dedup_marks = true,       -- Remove duplicate punctuation marks
	
	-- Autocommands
	enable_on_save = true,           -- Format on file save
	file_patterns = { "*.md", "*.txt", "*.norg" },
	
	-- Spacing configuration
	add_space_between_cjk_and_english = true,
	add_space_between_cjk_and_digit = true,
	add_space_around_markdown = true,  -- Space around inline code, bold, links
}

-- Current configuration
M.config = vim.deepcopy(M.defaults)

-- Setup function
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.defaults, opts)
	return M.config
end

-- Get configuration value
function M.get(key)
	return M.config[key]
end

-- Set configuration value
function M.set(key, value)
	M.config[key] = value
end

return M
