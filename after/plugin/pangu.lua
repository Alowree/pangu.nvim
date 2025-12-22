-- Neovim integration: autocommands and event handlers

local pangu = require("pangu")

-- Auto-format on file save (if enabled in config)
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = pangu.config.get("file_patterns"),
	callback = function()
		if pangu.config.get("enable_on_save") then
			pangu.format_buffer()
		end
	end,
	desc = "Auto-format text with pangu spacing rules",
})
