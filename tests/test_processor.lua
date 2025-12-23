-- Simple test runner for pangu.nvim processor
-- Mocks minimal `vim` functions used by the config module, adjusts package.path

local ROOT = "/Users/alowree/Desktop/pangu.nvim"
package.path = ROOT .. "/lua/?.lua;" .. ROOT .. "/lua/?/init.lua;" .. package.path

-- Minimal vim mock used by config.lua
vim = vim or {}

-- deep copy implementation
local function deepcopy(orig, seen)
	if type(orig) ~= "table" then
		return orig
	end
	if seen and seen[orig] then
		return seen[orig]
	end
	local s = seen or {}
	local res = {}
	s[orig] = res
	for k, v in pairs(orig) do
		res[deepcopy(k, s)] = deepcopy(v, s)
	end
	setmetatable(res, deepcopy(getmetatable(orig), s))
	return res
end

vim.deepcopy = vim.deepcopy or deepcopy

-- tbl_deep_extend simple implementation (mode ignored except for 'force')
vim.tbl_deep_extend = vim.tbl_deep_extend
	or function(mode, base, ...)
		local out = deepcopy(base or {})
		for i = 1, select("#", ...) do
			local t = select(i, ...)
			if type(t) == "table" then
				for k, v in pairs(t) do
					out[k] = v
				end
			end
		end
		return out
	end

-- Minimal API placeholder used nowhere in tests but safe to have
vim.api = vim.api or {}
vim.api.nvim_get_current_buf = vim.api.nvim_get_current_buf or function()
	return 0
end

-- Now require the module
local ok, pangu = pcall(require, "pangu")
if not ok then
	io.stderr:write("Failed to require pangu: " .. tostring(pangu) .. "\n")
	os.exit(2)
end

local tests = {
	{ input = "中文English中文", out = "中文 English 中文", desc = "CJK <-> English spacing" },
	{ input = "中文123中文", out = "中文 123 中文", desc = "CJK <-> Digit spacing" },
	-- Chinese characters on both sides of inline / bold / links
	{ input = "中文和`code`之间", out = "中文和 `code` 之间", desc = "CJK and inline code spacing" },
	{ input = "中文**粗体**中文", out = "中文 **粗体** 中文", desc = "CJK and bold spacing" },
	{
		input = "超链接样式[点击这里](http://example.com)有很多种",
		out = "超链接样式 [点击这里](http://example.com) 有很多种",
		desc = "CJK and link spacing",
	},
	-- Punctuation-adjacent tests: when one side is Chinese punctuation,
	-- only add space on the Chinese-character side, not the punctuation side.
	-- Inline code cases
	{
		input = "注意：`code`前面是标点符号时，不添加空格",
		out = "注意：`code` 前面是标点符号时，不添加空格",
		desc = "Code: punctuation before, add space after only",
	},
	{
		input = "注意`code`：后面是标点符号时，不添加空格",
		out = "注意 `code`：后面是标点符号时，不添加空格",
		desc = "Code: punctuation after, add space before only",
	},

	-- Bold (**...**) cases
	{
		input = "注意：**粗体**前面是标点符号时，不添加空格",
		out = "注意：**粗体** 前面是标点符号时，不添加空格",
		desc = "Bold: punctuation before, add space after only",
	},
	{
		input = "注意**粗体**：后面是标点符号时，不添加空格",
		out = "注意 **粗体**：后面是标点符号时，不添加空格",
		desc = "Bold: punctuation after, add space before only",
	},

	-- Link cases
	{
		input = "注意：[点击](http://example.com)前面是标点符号时，不添加空格",
		out = "注意：[点击](http://example.com) 前面是标点符号时，不添加空格",
		desc = "Link: punctuation before, add space after only",
	},
	{
		input = "注意[点击](http://example.com)：后面是标点符号时，不添加空格",
		out = "注意 [点击](http://example.com)：后面是标点符号时，不添加空格",
		desc = "Link: punctuation after, add space before only",
	},
	-- Punctuation versions
	{ input = "中文,", out = "中文，", desc = "Comma converted" },
	{ input = "中文.", out = "中文。", desc = "Period converted" },
	{ input = "中文?", out = "中文？", desc = "Question mark converted" },
	{ input = "中文!", out = "中文！", desc = "Exclamation mark converted" },
	{ input = "中文(备注)中文", out = "中文（备注）中文", desc = "Parentheses converted" },
	{ input = '中文"引用"中文', out = "中文“引用”中文", desc = "Double quote converted" },
	{ input = "中文'单引'中文", out = "中文‘单引’中文", desc = "Single quote converted" },
	-- Truncate repated punctuations
	{ input = "中文，，，", out = "中文，", desc = "Truncate repeated ，" },
	{ input = "中文。。。", out = "中文。", desc = "Truncate repeated 。" },
	{ input = "中文？？？", out = "中文？", desc = "Truncate repeated ？" },
	{ input = "中文！！！", out = "中文！", desc = "Truncate repeated ！" },
}

-- Test code block skipping functionality
local code_block_tests = {
	{
		desc = "Skip formatting inside code blocks when enabled",
		skip_enabled = true,
		-- When skip is enabled: line 3 (inside ```) should NOT be formatted
		-- So we should see both "中文 English" (formatted lines outside) AND "中文English" (unformatted inside)
		check_contains = "中文English",
		check_not_contains = nil,
	},
	{
		desc = "Format inside code blocks when skip disabled",
		skip_enabled = false,
		-- When skip is disabled: ALL lines should be formatted
		-- So we should NOT see any "中文English" pattern
		check_not_contains = "中文English",
		check_contains = "中文 English",
	},
}

-- Helper function to test code block skipping
local function test_code_block_skipping()
	local failures_cb = {}

	for _, test in ipairs(code_block_tests) do
		-- Save original config
		local orig_skip = pangu.config.get("skip_code_blocks")

		-- Set skip_code_blocks flag using the config API
		pangu.config.set("skip_code_blocks", test.skip_enabled)

		local input = "中文English\n```\n中文English\n```\n中文English"

		-- Split input into lines and process using the same logic as M.format_buffer
		local result_lines = {}
		local in_code_block = false
		for line in input:gmatch("[^\n]+") do
			-- Check if this line is a code block fence - in Lua patterns, match 3+ backticks as ```*
			if line:match("^%s*`%`%`%`*") then
				-- Always add fence line as-is
				table.insert(result_lines, line)
				-- Toggle code block state ONLY if skip is enabled
				if test.skip_enabled then
					in_code_block = not in_code_block
				end
			elseif in_code_block and test.skip_enabled then
				-- Inside code block and skip is enabled: keep as-is
				table.insert(result_lines, line)
			else
				-- Outside code block or skip disabled: format the line
				table.insert(result_lines, pangu.format(line))
			end
		end

		local result_text = table.concat(result_lines, "\n")

		-- Check assertions
		local passed = true

		if test.check_contains and not result_text:find(test.check_contains, 1, true) then
			passed = false
			io.stderr:write(
				string.format(
					"[FAIL] Code block test: %s\n  Should contain: '%s'\n  Got: %s\n\n",
					test.desc,
					test.check_contains,
					result_text
				)
			)
		end

		if test.check_not_contains and result_text:find(test.check_not_contains, 1, true) then
			passed = false
			io.stderr:write(
				string.format(
					"[FAIL] Code block test: %s\n  Should NOT contain: '%s'\n  Got: %s\n\n",
					test.desc,
					test.check_not_contains,
					result_text
				)
			)
		end

		if passed then
			io.stdout:write(string.format("[OK] Code block test: %s\n", test.desc))
		else
			table.insert(failures_cb, { desc = test.desc, skip_enabled = test.skip_enabled })
		end

		-- Restore original config
		pangu.config.set("skip_code_blocks", orig_skip)
	end

	return failures_cb
end

-- Run code block tests
io.stdout:write("\n--- Code Block Skipping Tests ---\n")
local code_block_failures = test_code_block_skipping()

local failures = {}
for i, t in ipairs(tests) do
	local got = pangu.format(t.input)
	if got ~= t.out then
		table.insert(failures, { idx = i, desc = t.desc, input = t.input, want = t.out, got = got })
		io.stderr:write(
			string.format("[FAIL] %s\n  input: %s\n  want:  %s\n  got:   %s\n\n", t.desc, t.input, t.out, got)
		)
	else
		io.stdout:write(string.format("[OK] %s\n", t.desc))
	end
end

-- Combine all failures
for _, f in ipairs(code_block_failures) do
	table.insert(failures, f)
end

if #failures > 0 then
	io.stderr:write(string.format("\n%d tests failed\n", #failures))
	os.exit(1)
else
	io.stdout:write("\nAll tests passed\n")
	os.exit(0)
end
