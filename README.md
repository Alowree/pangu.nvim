# pangu.nvim

A Neovim plugin that adds proper spacing between CJK (Chinese, Japanese, Korean) and English/Digits, along with Chinese punctuation normalization and formatting.

## Features

- **CJK-English Spacing**: Automatically adds spaces between Chinese characters and English words
- **CJK-Digit Spacing**: Adds spaces between Chinese characters and numbers
- **Punctuation Conversion**: Converts English punctuation to proper Chinese punctuation after CJK characters
  - `,` → `，` (comma)
  - `\` → `、` (enumeration comma)
  - `.` → `。` (period)
  - `:` → `：` (colon)
  - `;` → `；` (semicolon)
  - `?` → `？` (question mark)
  - `!` → `！` (exclamation mark)
- **Parenthesis Conversion**: Converts `()` to `（）` around CJK text
- **Duplicate Mark Normalization**:
  - `。。。` → `……` (ellipsis)
  - Multiple `？` or `！` → single mark
  - Multiple duplicate punctuation → single mark
- **Markdown Support**: Handles spacing around inline code, bold, and links
- **Code Block Skipping**: Preserves content inside Markdown code blocks (` ``` `) without formatting
- **Auto-format on Save**: Optional automatic formatting when saving files
- **Flexible Configuration**: Enable/disable specific rules as needed

## Installation

Using your preferred plugin manager, e.g., with `lazy.nvim`:

### Recommended: Lazy Load by File Type

For better startup performance, lazy load the plugin when opening specific file types:

```lua
{
  "alowree/pangu.nvim",
  ft = { "markdown", "text", "norg" },  -- Lazy load for these file types
  config = function()
    require("pangu").setup({
      enable_spacing = true,
      enable_punct_convert = true,
      enable_paren_convert = true,
      enable_dedup_marks = true,
      enable_on_save = true,
      skip_code_blocks = true,
      file_patterns = { "*.md", "*.txt", "*.norg" },
    })
  end
}
```

This configuration ensures the plugin only loads when you open a markdown, text, or norg file, keeping your Neovim startup fast.

### Alternative: Load on Command

If you prefer to load it on demand via command:

```lua
{
  "alowree/pangu.nvim",
  cmd = { "Pangu", "PanguLine", "PanguSelection" },
  config = function()
    require("pangu").setup()
  end
}
```

### Traditional Setup

For always-on loading:

```lua
{
  "alowree/pangu.nvim",
  config = function()
    require("pangu").setup({
      enable_spacing = true,
      enable_punct_convert = true,
      enable_paren_convert = true,
      enable_dedup_marks = true,
      enable_on_save = true,
      skip_code_blocks = true,
      file_patterns = { "*.md", "*.txt", "*.norg" },
    })
  end
}
```

Or with `packer.nvim`:

```lua
use {
  'alowree/pangu.nvim',
  config = function()
    require('pangu').setup()
  end
}
```

## Configuration

### Default Configuration

````lua
{
  -- Spacing (master toggle)
  enable_spacing = true,           -- Master toggle for spacing rules; when true the three
                                    -- options below control specific spacing behaviors

  -- Spacing sub-options (effective only when `enable_spacing = true`)
  add_space_between_cjk_and_english = true,  -- Add space between CJK and English
  add_space_between_cjk_and_digit = true,    -- Add space between CJK and digits
  add_space_around_markdown = true,          -- Add spaces around inline code / bold / links

  -- Other formatting rules
  enable_punct_convert = true,     -- Convert English to Chinese punctuation
  enable_paren_convert = true,     -- Convert () to （）
  enable_quote_convert = true,     -- Convert ASCII quotes to Chinese quotes in CJK contexts
  enable_dedup_marks = true,       -- Remove duplicate punctuation marks

  -- Markdown code block handling
  skip_code_blocks = true,         -- Skip formatting inside ``` ``` code blocks

  -- Autocommands
  enable_on_save = true,           -- Auto-format on file save
  file_patterns = { "*.md", "*.txt", "*.norg" },
}
````

### Setup Example

```lua
require("pangu").setup({
  enable_on_save = false,  -- Disable auto-formatting
  enable_punct_convert = false,  -- Only do spacing
})
```

### Code Block Handling

By default, the plugin skips formatting content inside Markdown code blocks. This is useful when you have code examples or technical content that should not be modified:

```lua
require("pangu").setup({
  skip_code_blocks = true,  -- Enable (default)
  -- or
  skip_code_blocks = false,  -- Disable to format everything
})
```

**How it works:**

- When `skip_code_blocks = true`, any text between ` ``` ` markers is preserved as-is
- The fence markers themselves (` ``` `) are also left unchanged
- This works with any number of backticks (` ``` `, ` ```` `, ` ````` `, etc.)
- Useful for:
  - Code examples in markdown documentation
  - Code snippets you want to preserve exactly
  - Technical content that shouldn't be reformatted

## Usage

### Commands

- `:Pangu` - Format entire buffer
- `:PanguLine` - Format current line
- `:PanguSelection` - Format selected text (visual mode)
- `:PanguVersion` - Show plugin version

### Programmatic Usage

```lua
local pangu = require("pangu")

-- Format a string
local formatted = pangu.format("中文English中文")
-- Result: "中文 English 中文"

-- Format current buffer
pangu.format_buffer()

-- Format a range
pangu.format_range(10, 20)  -- Lines 10-20
```

## Module Structure

```
~/Desktop/pangu.nvim/
├── lua/pangu/
│   ├── init.lua          # Public API entry point
│   ├── processor.lua     # Core formatting logic (spacing, punctuation, dedup)
│   ├── tokenizer.lua     # UTF-8 aware text tokenization
│   ├── config.lua        # Configuration management
│   └── utils.lua         # Character detection helpers
├── plugin/
│   └── pangu.lua         # Commands registration (:Pangu, etc.)
├── after/plugin/
│   └── pangu.lua         # Autocommand setup
├── README.md             # Documentation
├── LICENSE               # MIT License
└── .gitignore
```

### Module Responsibilities

- **init.lua**: Exports the public API and coordinates between modules
- **config.lua**: Manages configuration defaults and user options
- **processor.lua**: Implements all formatting transformations (spacing, punctuation, deduplication)
- **tokenizer.lua**: Handles UTF-8 aware text splitting and token classification
- **utils.lua**: Character detection functions (Chinese, English, punctuation, etc.)

## Examples

### Formatting Functions

**1. CJK-English Spacing** (controlled by `enable_spacing` → `add_space_between_cjk_and_english`)

```
Input:  中文English中文
Output: 中文 English 中文
```

**2. CJK-Digit Spacing** (controlled by `enable_spacing` → `add_space_between_cjk_and_digit`)

```
Input:  中文123中文
Output: 中文 123 中文
```

**3. Markdown Spacing** (controlled by `enable_spacing` → `add_space_around_markdown`)

```
Input:  中文和`code`之间
Output: 中文和 `code` 之间

Input:  中文**粗体**中文
Output: 中文 **粗体** 中文

Input:  点击[这里](https://example.com)查看
Output: 点击 [这里](https://example.com) 查看
```

**4. Punctuation Conversion** (controlled by `enable_punct_convert`)

English to Chinese type conversions:

```
Input:  中文,
Output: 中文，

Input:  中文.
Output: 中文。

Input:  中文?
Output: 中文？

Input:  中文!
Output: 中文！
```

Note: the plugin performs punctuation conversion only from English to Chinese when the punctuation follows Chinese content. It does not automatically convert Chinese punctuation to English.

**5. Parentheses Conversion** (controlled by `enable_paren_convert`)

Parentheses conversion is also bidirectional and context-aware:

- Convert `(` to `（` when it follows Chinese content, and convert `）` accordingly to match.
- Convert `（` to `(` when it follows English or digits, and convert `)` accordingly to match.

English to Chinese type conversions:

```
Input:  中文(备注)中文
Output: 中文（备注）中文
```

Chinese to English type conversions:

```
Input:  English （note） English
Output: English (note) English
```

**6. Quote Conversion** (controlled by `enable_quote_convert`)

Quote conversion is applied only when ASCII quotes appear in CJK contexts (convert to Chinese quotes). Existing Chinese quotes in English contexts are left unchanged.

English to Chinese type conversions:

```
Input:  中文"引用"中文
Output: 中文“引用”中文

Input:  中文'单引'中文
Output: 中文‘单引’中文
```

Chinese to English type conversions - DO NOTHING:

```
Input:  English “double quoted content” with more words
Output: English “double quoted content” with more words

Input:  English ‘single quoted content’ with more words
Output: English ‘single quoted content’ with more words
```

**7. Punctuation Mark Deduplication** (controlled by `enable_dedup_marks`)

```
Input:  中文。。。
Output: 中文。

Input:  中文？？？
Output: 中文？

Input:  中文！！！
Output: 中文！

Input:  中文，，，
Output: 中文，
```

**8. Code Block Preservation** (controlled by `skip_code_blocks`)

When enabled, the plugin preserves content inside Markdown code blocks without applying any formatting:

````
Input:
```
这是代码块内的中文English文本
```

Output:
```
这是代码块内的中文English文本
```

With `skip_code_blocks = true`, the content inside `` ``` `` is left unchanged.
With `skip_code_blocks = false`, formatting is applied to all text including code blocks.
````

### Combined Example

```
Input:  中文English123和(括号)里的"引用"。。。？？？
Output: 中文 English 123 和（括号）里的“引用”。？
```

### Code Block Example

When `skip_code_blocks = true` (default):

````
Input:
普通段落中的中文English文本

```python
# 代码块内的内容不会被格式化
中文English代码示例
```

另一个普通段落中的中文English文本

Output:
普通段落中的中文 English 文本

```python
# 代码块内的内容不会被格式化
中文English代码示例
```

另一个普通段落中的中文 English 文本
````

Notice how the text outside the code blocks gets formatted (space added between 中文 and English), but the text inside the code block remains unchanged.

## Development

### Adding New Features

To add a new formatting rule:

1. Create a transformation function in [processor.lua](lua/pangu/processor.lua)
2. Add corresponding config flag in [config.lua](lua/pangu/config.lua)
3. Call the new function in `M.format()` with appropriate guards
4. Add tests and update documentation

### File Patterns

To add auto-formatting for additional file types, modify the configuration:

```lua
require("pangu").setup({
  file_patterns = { "*.md", "*.txt", "*.norg", "*.rst" },
})
```

## License

MIT License

## Acknowledgments

Based on the pangu spacing concept to improve CJK text readability.
