local M = {}

function M.setup()
	local config = require("pangu.config")
	local maps = config.get("keymaps")

	if not maps then
		return
	end

	-- 1. Toggle Plugin
	if maps.pangu_toggle then
		vim.keymap.set("n", maps.pangu_toggle, "<cmd>PanguToggle<CR>", { desc = "Toggle pangu.nvim" })
	end

	-- 2. Format Line
	if maps.pangu_line then
		vim.keymap.set("n", maps.pangu_line, "<cmd>PanguLine<CR>", { desc = "Pangu format current line" })
	end

	-- 3. Ignore Selection (Visual Mode)
	if maps.pangu_ignore_selection then
		vim.keymap.set(
			"v",
			maps.pangu_ignore_selection,
			":PanguIgnore<CR>",
			{ desc = "Wrap selection with pangu-ignore tags" }
		)
	end

	-- 4. Ignore Cleanup
	if maps.pangu_ignore_cleanup then
		vim.keymap.set(
			{ "n", "v" },
			maps.pangu_ignore_cleanup,
			"<cmd>PanguIgnoreCleanup<CR>",
			{ desc = "Remove surrounding pangu-ignore tags" }
		)
	end
end

return M
