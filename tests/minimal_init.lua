local root = vim.fn.fnamemodify(".", ":p")

-- 1. Add your own plugin to the path
vim.opt.runtimepath:append(root)

-- 2. Add Plenary to the path (ADJUST THIS PATH if needed)
local plenary_path = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
if vim.fn.isdirectory(plenary_path) == 0 then
	print("Error: Could not find plenary at " .. plenary_path)
end
vim.opt.runtimepath:append(plenary_path)

-- 3. Ensure the lua folders are discoverable
package.path = root .. "lua/?.lua;" .. package.path
