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

	-- CALL KEYMAP SETUP HERE
	-- We require it inline to keep the top-level imports clean
	require("pangu.keymaps").setup()
end

-- Format current buffer or a specific bufnr
function M.format_buffer(bufnr)
	M.processor.format_buffer(bufnr)
end

-- Format specific range
function M.format_range(start_line, end_line)
	M.processor.format_range(nil, start_line, end_line)
end

-- Format a string and return the result
function M.format(text)
	return M.processor.format(text)
end

function M.toggle()
	local current = M.config.get("enabled")
	local new_state = not current
	M.config.set("enabled", new_state)
	return new_state
end

--- Returns a string representing the current status for statuslines
function M.get_status()
	local enabled = M.config.get("enabled")
	if not enabled then
		return "󱅔 Pangu" -- Or "Pangu: OFF"
	end
	return "󱅓 Pangu" -- Or "Pangu: ON"
end

-- Get version
M.version = "0.1.0"

return M
