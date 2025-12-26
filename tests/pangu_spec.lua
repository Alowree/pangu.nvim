local pangu = require("pangu.processor")
local config = require("pangu.config")

describe("pangu.nvim Comprehensive Suite", function()
	before_each(function()
		-- Reset to a known default state before each test
		config.setup({
			enable_spacing = true,
			add_space_around_markdown = true,
			enable_punct_convert = true,
			enable_paren_convert = true,
			enable_quote_convert = true,
			enable_dedup_marks = true,
			skip_code_blocks = true,
		})
	end)

	-- Helper for table-driven tests
	local function run_tests(test_cases)
		for _, case in ipairs(test_cases) do
			it(case.desc, function()
				assert.are.same(case.expected, pangu.format(case.input))
			end)
		end
	end

	describe("Basic Spacing", function()
		run_tests({
			{ desc = "CJK and English", input = "中文English中文", expected = "中文 English 中文" },
			{ desc = "CJK and Digits", input = "中文123中文", expected = "中文 123 中文" },
		})
	end)

	describe("Markdown Spacing", function()
		run_tests({
			{ desc = "Inline code", input = "中文`code`中文", expected = "中文 `code` 中文" },
			{
				desc = "Double backtick inline code",
				input = "中文``double code``中文",
				expected = "中文 ``double code`` 中文",
			},
			{
				desc = "Double backticks containing single backticks",
				input = "中文``code with ` backtick``中文",
				expected = "中文 ``code with ` backtick`` 中文",
			},
			{ desc = "Italic with asterisks", input = "中文*italic*中文", expected = "中文 *italic* 中文" },
			{ desc = "Italic with underscores", input = "中文_italic_中文", expected = "中文 _italic_ 中文" },
			{ desc = "Bold with asterisks", input = "中文**bold**中文", expected = "中文 **bold** 中文" },
			{ desc = "Bold with underscores", input = "中文__bold__中文", expected = "中文 __bold__ 中文" },
			{
				desc = "Bold-Italic with asterisks",
				input = "中文***bold-italic***中文",
				expected = "中文 ***bold-italic*** 中文",
			},
			{
				desc = "Bold-Italic with underscores",
				input = "中文___bold-italic___中文",
				expected = "中文 ___bold-italic___ 中文",
			},
			{
				desc = "Nested emphasis inside mixed",
				input = "中文***bold and _italic_***中文",
				expected = "中文 ***bold and _italic_*** 中文",
			},
			{ desc = "Links", input = "点击[这里](url)查看", expected = "点击 [这里](url) 查看" },
			{
				desc = "No space if punctuation precedes code",
				input = "注意：`code`前面有标点时",
				expected = "注意：`code` 前面有标点时",
			},
			{
				desc = "No space if punctuation follows code",
				input = "注意`code`：之后有标点时",
				expected = "注意 `code`：之后有标点时",
			},
			{
				desc = "No space if punctuation precedes bold",
				input = "看：**这个**测试",
				expected = "看：**这个** 测试",
			},
			{
				desc = "No space if punctuation follows bold",
				input = "看**这个**：测试",
				expected = "看 **这个**：测试",
			},
			{
				desc = "No space if punctuation precedes link",
				input = "看：[链接](url)测试",
				expected = "看：[链接](url) 测试",
			},
			{
				desc = "No space if punctuation follows link",
				input = "看[链接](url)：测试",
				expected = "看 [链接](url)：测试",
			},
		})
	end)

	describe("Punctuation Conversion", function()
		run_tests({
			{ desc = "Comma and Period", input = "你好,世界.", expected = "你好，世界。" },
			{ desc = "Question and Exclamation", input = "真的吗?好!", expected = "真的吗？好！" },
			{ desc = "Colon and Semicolon", input = "看:", expected = "看：" },
		})
	end)

	describe("Parentheses (Bidirectional)", function()
		run_tests({
			{ desc = "English to Chinese (after CJK)", input = "中文(备注)", expected = "中文（备注）" },
			{ desc = "Chinese to English (after English)", input = "English（note）", expected = "English (note)" },
		})
	end)

	describe("Quote Conversion", function()
		run_tests({
			{ desc = "Double quotes in CJK", input = '中文"引用"中文', expected = "中文“引用”中文" },
			{ desc = "Single quotes in CJK", input = "中文'单引'中文", expected = "中文‘单引’中文" },
			{
				desc = "Preserve Chinese quotes in English",
				input = "English “quoted” English",
				expected = "English “quoted” English",
			},
		})
	end)

	describe("Deduplication", function()
		run_tests({
			{ desc = "Repeated periods", input = "完成。。。 ", expected = "完成。 " },
			{ desc = "Repeated question marks", input = "为什么？？？", expected = "为什么？" },
			{ desc = "Repeated exclamation marks", input = "天呐！！！", expected = "天呐！" },
		})
	end)

	describe("Combined Cases", function()
		run_tests({
			{
				desc = "Complex sentence",
				input = '中文English更多123和(括号)里的"引用"。。。为什么？？？',
				expected = "中文 English 更多 123 和（括号）里的“引用”。为什么？",
			},
		})
	end)

	describe("Buffer-level Logic (Code Blocks)", function()
		it("skips formatting inside code block fences", function()
			-- 1. Create a scratch buffer
			local bufnr = vim.api.nvim_create_buf(false, true)

			-- 2. Set lines: outside, inside, outside
			local input_lines = {
				"中文English", -- Should be formatted
				"```",
				"中文English", -- Should NOT be formatted
				"```",
				"中文English", -- Should be formatted
			}
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, input_lines)

			-- 3. Run the buffer formatter
			local processor = require("pangu.processor")
			processor.format_buffer(bufnr)

			-- 4. Verify results
			local result_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

			assert.are.same("中文 English", result_lines[1])
			assert.are.same("中文English", result_lines[3]) -- Still unformatted
			assert.are.same("中文 English", result_lines[5])
		end)

		it("formats inside code blocks if skip_code_blocks is false", function()
			config.set("skip_code_blocks", false)
			local bufnr = vim.api.nvim_create_buf(false, true)

			local input_lines = { "```", "中文English", "```" }
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, input_lines)

			require("pangu.processor").format_buffer(bufnr)

			local result_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			assert.are.same("中文 English", result_lines[2]) -- Now it is formatted
		end)
	end)

	describe("Buffer-level Logic (Nested Code Fences)", function()
		local processor = require("pangu.processor")
		local config = require("pangu.config")

		it("does not exit a 4-backtick block when encountering a 3-backtick fence", function()
			-- Set up a virtual buffer
			local bufnr = vim.api.nvim_create_buf(false, true)
			local lines = {
				"Outside block: 中文English",
				"````",
				"Inside 4-backtick block: 中文English",
				"```",
				"Still inside 4-backtick block: 中文English",
				"```",
				"````",
				"Outside again: 中文English",
			}
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

			-- Ensure skip is enabled
			config.set("skip_code_blocks", true)
			processor.format_buffer(bufnr)

			local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

			-- Outside should be formatted
			assert.are.equal("Outside block: 中文 English", result[1])
			-- Inside should remain UNTOUCHED despite the 3-backtick lines
			assert.are.equal("Inside 4-backtick block: 中文English", result[3])
			assert.are.equal("```", result[4])
			assert.are.equal("Still inside 4-backtick block: 中文English", result[5])
			-- Outside should be formatted
			assert.are.equal("Outside again: 中文 English", result[8])
		end)

		it("correctly closes a block with a LARGER fence (standard Markdown behavior)", function()
			local bufnr = vim.api.nvim_create_buf(false, true)
			local lines = {
				"```",
				"Inside 3-backtick block: 中文English",
				"````", -- A 4-backtick fence can close a 3-backtick block
				"Outside: 中文English",
			}
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

			config.set("skip_code_blocks", true)
			processor.format_buffer(bufnr)

			local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			assert.are.equal("Inside 3-backtick block: 中文English", result[2])
			assert.are.equal("Outside: 中文 English", result[4])
		end)

		it("respects indented code fences", function()
			local bufnr = vim.api.nvim_create_buf(false, true)
			local lines = {
				"  ```",
				"  Indented code: 中文English",
				"  ```",
				"Outside: 中文English",
			}
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

			config.set("skip_code_blocks", true)
			processor.format_buffer(bufnr)

			local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			assert.are.equal("  Indented code: 中文English", result[2])
			assert.are.equal("Outside: 中文 English", result[4])
		end)
	end)

	describe("Buffer-level Logic (Manual Ignore)", function()
		local processor = require("pangu.processor")
		it("skips formatting between ignore-start and ignore-end tags", function()
			local bufnr = vim.api.nvim_create_buf(false, true)
			local lines = {
				"Format: 中文English",
				"pangu-ignore-start", -- Add this
				"Ignore: 中文English",
				"Keep spacing: 中文English",
				"pangu-ignore-end", -- Add this
				"Format: 中文English",
			}
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

			processor.format_buffer(bufnr)

			local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

			assert.are.equal("Format: 中文 English", result[1])
			-- These should remain unformatted because they are between the tags
			assert.are.equal("Ignore: 中文English", result[3])
			assert.are.equal("Keep spacing: 中文English", result[4])
			-- This is after the end tag, so it should be formatted
			assert.are.equal("Format: 中文 English", result[6])
		end)
	end)
end)
