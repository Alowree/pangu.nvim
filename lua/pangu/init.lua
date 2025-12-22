-- pangu.nvim - Main module entry point
-- A Neovim plugin that adds proper spacing between CJK and English/Digits

local M = {}

-- Import submodules
M.config = require("pangu.config")
M.processor = require("pangu.processor")
M.tokenizer = require("pangu.tokenizer")
M.utils = require("pangu.utils")

-- Setup function - initialize the plugin with options
function M.setup(opts)
	M.config.setup(opts or {})
end

-- Format current buffer
function M.format_buffer()
	M.processor.format_buffer()
end

-- Format specific range
function M.format_range(start_line, end_line)
	M.processor.format_range(nil, start_line, end_line)
end

-- Format a string and return the result
function M.format(text)
	return M.processor.format(text)
end

-- Get version
M.version = "0.1.0"

return M
