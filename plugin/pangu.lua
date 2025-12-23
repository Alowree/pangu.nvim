-- Plugin initialization and command registration

local pangu = require("pangu")

-- Setup with default config
pangu.setup()

-- User command: Format entire buffer
vim.api.nvim_create_user_command("Pangu", function()
	pangu.format_buffer()
end, {})

-- User command: Format current line
vim.api.nvim_create_user_command("PanguLine", function()
	local line = vim.fn.line(".")
	pangu.format_range(line, line)
end, {})

-- User command: Format selection (visual mode)
vim.api.nvim_create_user_command("PanguSelection", function()
	local start_line = vim.fn.getpos("'<")[2]
	local end_line = vim.fn.getpos("'>")[2]
	pangu.format_range(start_line, end_line)
end, { range = true })

-- User command: Show version
vim.api.nvim_create_user_command("PanguVersion", function()
	print("pangu.nvim v" .. pangu.version)
end, {})

print("pangu.nvim loaded")
