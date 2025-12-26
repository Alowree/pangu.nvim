# pangu.nvim

pangu.nvim is a Neovim plugin that enhances text readability by automatically applying proper spacing and converting punctuation and quotes in mixed-language content, primarily focusing on CJK and English text.

## Features

- **Intelligent Spacing:**
  - Adds spaces between CJK characters and English letters/digits (`enable_spacing_basic`).
  - Adds spaces around markdown elements like inline code (`code`), bold (`**bold**`), italics (`*italic*`), and links (`[text](url)`) (`enable_spacing_expanded`).

- **Punctuation Conversion:** Converts common English punctuation (`, . ? ! : ;`) to their full-width Chinese equivalents when appropriate (`enable_punct_convert`). This conversion primarily occurs when punctuation follows CJK content.

- **Parentheses Conversion:** Bidirectionally converts parentheses. For example, `()` to `（）` when following CJK text, and `（）` to `()` when following English text (`enable_paren_convert`).

- **Quote Conversion:** Converts ASCII quotes (`"` , `'`) to Chinese quotes (`“ ”`, `‘ ’`) when they enclose CJK content (`enable_quote_convert`). Existing Chinese quotes in English contexts are left unchanged.

- **Mark Deduplication:** Reduces repeated punctuation marks like `???` or `。` to a single instance (`enable_dedup_marks`).

- **Smart Code Block Handling:**
  - By default, skips formatting inside markdown code blocks (delimited by ` ``` ` or ` ```` `) (`skip_code_blocks`).
  - Correctly handles nested code fences of different lengths (e.g., a 4-backtick fence can close a 3-backtick block).
  - Ignores text between `pangu-ignore-start` and `pangu-ignore-end` tags, allowing manual exclusion of content from formatting. This is useful for preserving auto-generated content like tables.

- **Auto-formatting on Save:** Optionally formats files automatically when saved, configurable by file patterns (`enable_on_save`, `file_patterns`).

## Installation

Install `pangu.nvim` using your preferred Neovim package manager, e.g., with `lazy.nvim`.

### Recommended: Lazy Load by File Type

For better startup performance, lazy load the plugin when opening specific file types:

```lua
{
  "alowree/pangu.nvim",
  ft = { "markdown", "text", "norg" },  -- Lazy load for these file types
  config = function()
    require("pangu").setup({
      -- Your custom configuration options here, e.g.:
      -- enable_spacing_basic = true,
      -- enable_punct_convert = true,
    })
  end,
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
    require("pangu").setup({})
  end
}
```

### Traditional Setup

For always-on loading:

```lua
{
  "alowree/pangu.nvim",
  config = function()
    require("pangu").setup({})
  end
}
```

Or with `packer.nvim`:

```lua
use {
  'alowree/pangu.nvim',
  config = function()
    require('pangu').setup({})
  end
}
```

## Configuration

Call the `setup` function in your Neovim configuration (e.g., `init.lua` or a dedicated plugin configuration file) to customize `pangu.nvim`.

### Default options

`````lua
require("pangu").setup({
  -- Master enable/disable for the plugin
  enabled = true,

  -- Add spaces between CJK and English/Digit
  enable_spacing_basic = true,
  -- Space around inline code, bold, links, etc.
  enable_spacing_expanded = true,

  -- Convert English punctuation to Chinese full-width equivalents
  enable_punct_convert = true,
  -- Convert English parentheses to Chinese parentheses and vice-versa
  enable_paren_convert = true,
  -- Convert ASCII quotes to Chinese quotes in CJK contexts
  enable_quote_convert = true,
  -- Remove duplicate punctuation marks (e.g., '???' -> '?')
  enable_dedup_marks = true,

  -- Auto-formatting on save
  enable_on_save = true,
  -- File patterns for auto-formatting on save (glob patterns)
  -- Example: { "*.md", "*.txt", "*.norg" }
  file_patterns = { "*.md", "*.txt", "*.norg" },

  -- Skip formatting inside markdown code blocks (``` or ````)
  skip_code_blocks = true,

  -- Default keymaps (can be overridden)
  keymaps = {
    toggle = "<leader>pt",         -- Toggle plugin enabled/disabled
    format_line = "<leader>pl",   -- Format current line
    ignore_selection = "<leader>pi", -- Wrap selection with ignore tags (Visual mode)
    ignore_cleanup = "<leader>pc", -- Remove surrounding ignore tags
  },
})
`````

Refer to `lua/pangu/config.lua` for a complete list of all configuration options.

## Usage

### Commands

| Command               | Description                                              |
| --------------------- | -------------------------------------------------------- |
| `:Pangu`              | Format the entire buffer                                 |
| `:PanguLine`          | Format the current line                                  |
| `:PanguSelection`     | Format visual selection                                  |
| `:PanguToggle`        | Toggle plugin functionality on/off                       |
| `:PanguEnable`        | Manually enable the plugin                               |
| `:PanguDisable`       | Manually disable the plugin                              |
| `:PanguVersion`       | Show plugin version                                      |
| `:PanguIgnore`        | Wrap selection/line in ignore tags                       |
| `:PanguIgnoreCleanup` | Remove surrounding ignore tags and normalize whitespace. |

### Default Keymaps

The following keymaps are set up by default, assuming `<leader>` is your leader key. These can be customized via the `keymaps` table in the `setup` function.

- `<leader>pt`: Executes `:PanguToggle`
- `<leader>pl`: Executes `:PanguLine`
- `<leader>pi`: Executes `:PanguIgnore` (in Visual mode)
- `<leader>pc`: Executes `:PanguIgnoreCleanup`

### Statusline Integration

You can display the Pangu status in your statusline (supports icons).

```lua
require('lualine').setup({
  sections = {
    lualine_x = {
      { function() return require('pangu').get_status() end }
    }
  }
})
```

### Examples

#### 1. Spacing Logic

Controlled by `enable_spacing_basic`.

<!-- pangu-ignore-start -->

| Type              | Input           | Output            |
| :---------------- | :-------------- | :---------------- |
| **CJK & English** | 中文English中文 | 中文 English 中文 |
| **CJK & Digits**  | 第1步           | 第 1 步           |

<!-- pangu-ignore-end -->

#### 2. Markdown Intelligence

Controlled by `enable_spacing_expanded`. Pangu adds spaces around Markdown elements but respects punctuation boundaries (no extra space if a Chinese punctuation mark is already adjacent).

<!-- pangu-ignore-start -->

| Element         | Input               | Output                                        |
| :-------------- | :------------------ | :-------------------------------------------- |
| **Links**       | 点击[这里](url)查看 | 点击 [这里](url) 查看                         |
| **Bold**        | 这是**重要**提示    | 这是 **重要** 提示                            |
| **Inline Code** | 运行`make`命令      | 运行 `make` 命令                              |
| **Boundary**    | 注意：[链接](url)   | 注意：[链接](url) (No space added after `：`) |

<!-- pangu-ignore-end -->

#### 3. Punctuation & Parentheses

Controlled by `enable_punct_convert` and `enable_paren_convert`.

<!-- pangu-ignore-start -->

| Rule                 | Input           | Output           |
| :------------------- | :-------------- | :--------------- |
| **Punctuation**      | 你好,世界.      | 你好，世界。     |
| **To Chinese Paren** | 中文(备注)      | 中文（备注）     |
| **To English Paren** | English（note） | English (note)   |
| **Nested Logic**     | (中文(备注))    | （中文（备注）） |

<!-- pangu-ignore-end -->

#### 4. Quote Conversion

Controlled by `enable_quote_convert`. Converts ASCII quotes to "curly" Chinese quotes only when CJK characters are detected inside or adjacent to the quotes. Existing Chinese quotes in English contexts are left unchanged.

<!-- pangu-ignore-start -->

| Input           | Output          | Context                               |
| :-------------- | :-------------- | :------------------------------------ |
| 中文"引用"内容  | 中文“引用”内容  | **Converted** (CJK context)           |
| He said "Hello" | He said "Hello" | **Ignored** (English context)         |
| He said “Hello” | He said “Hello” | **Ignored** (Debateable)              |
| ‘中文’          | ‘中文’          | **Preserved** (Already Chinese style) |

<!-- pangu-ignore-end -->

#### 5. Deduplication

Controlled by `enable_dedup_marks`. Automatically collapses multiple repeated punctuation marks into a single instance.

<!-- pangu-ignore-start -->

| Input            | Output       |
| :--------------- | :----------- |
| 到底为什么？？？ | 到底为什么？ |
| 完成。。。       | 完成。       |
| 天呐！！！       | 天呐！       |
| 重复，，，       | 重复，       |

<!-- pangu-ignore-end -->

#### 6. Code Block Preservation

Controlled by `skip_code_blocks`. This ensures your code snippets remain functional and unformatted.

When enabled, the plugin preserves content inside Markdown code blocks without applying any formatting:

````markdown
Input:

```python
# This content is NOT formatted
print("中文English")
```

Output:

```python
# This content is NOT formatted
print("中文English")
```

With `skip_code_blocks = true`, the content inside ` ``` ` is left unchanged.
With `skip_code_blocks = false`, formatting is applied to all text including code blocks.
````

#### 7. Disable pangu formatting (Ignore Tags)

The `pangu-ignore-start` and `pangu-ignore-end` comments are directives used to disable pangu formatting for a specific range of code. This feature is primarily designed for use within Markdown files to preserve the formatting of auto-generated content like tables or documentation.

| Context    | Example Syntax                | Will Pangu find it?                  |
| ---------- | ----------------------------- | ------------------------------------ |
| Plain Text | `pangu-ignore-start`          | Yes                                  |
| Markdown   | `<!-- pangu-ignore-start -->` | Yes (because it contains the string) |
| Lua Code   | `-- pangu-ignore-start`       | Yes (because it contains the string) |
| LaTeX      | `% pangu-ignore-start`        | Yes (because it contains the string) |

#### 8. Combined Example

A demonstration of all rules working together in a complex sentence.

```
Input:  中文English更多123和(括号)里的"引用"。。。为什么？？？
Output: 中文 English 更多 123 和（括号）里的“引用”。为什么？
```

## File Structure

```
~/Desktop/pangu.nvim/
├── lua/pangu/
│   ├── init.lua          # Public API entry point
│   ├── processor.lua     # Core formatting logic (spacing, punctuation, dedup)
│   ├── tokenizer.lua     # UTF-8 aware text tokenization
│   ├── config.lua        # Configuration management
│   ├── keymaps.lua       # Default keymaps
│   └── utils.lua         # Character detection helpers
├── plugin/
│   └── pangu.lua         # Commands registration (:Pangu, etc.)
├── README.md             # Documentation
├── LICENSE               # MIT License
└── .gitignore
```

### Module Responsibilities

- **init.lua**: Exports the public API and coordinates between modules.
- **config.lua**: Manages configuration defaults and user options.
- **processor.lua**: Implements all formatting transformations (spacing, punctuation, deduplication).
- **tokenizer.lua**: Handles UTF-8 aware text splitting and token classification.
- **utils.lua**: Character detection functions (Chinese, English, punctuation, etc.).

## Contributing

Contributions are welcome! Please refer to the tests in `tests/pangu_spec.lua` for examples of expected behavior and how to add new test cases.

## License

MIT License.
