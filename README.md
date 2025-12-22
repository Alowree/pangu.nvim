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
- **Auto-format on Save**: Optional automatic formatting when saving files
- **Flexible Configuration**: Enable/disable specific rules as needed

## Installation

Using your preferred plugin manager, e.g., with `lazy.nvim`:

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

```lua
{
  enable_spacing = true,           -- Add spaces between CJK and English/Digit
  enable_punct_convert = true,     -- Convert English to Chinese punctuation
  enable_paren_convert = true,     -- Convert () to （）
  enable_dedup_marks = true,       -- Remove duplicate punctuation marks
  enable_on_save = true,           -- Auto-format on file save
  file_patterns = { "*.md", "*.txt", "*.norg" },
  add_space_between_cjk_and_english = true,
  add_space_between_cjk_and_digit = true,
  add_space_around_markdown = true,
}
```

### Setup Example

```lua
require("pangu").setup({
  enable_on_save = false,  -- Disable auto-formatting
  enable_punct_convert = false,  -- Only do spacing
})
```

## Usage

### Commands

- `:PanguFormat` - Format entire buffer
- `:PanguFormatLine` - Format current line
- `:PanguFormatSelection` - Format selected text (visual mode)
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
│   └── pangu.lua         # Commands registration (:PanguFormat, etc.)
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

### Before and After

```
Input:  "中文English中文"
Output: "中文 English 中文"

Input:  "中文123中文"
Output: "中文 123 中文"

Input:  "中文,中文"
Output: "中文，中文"

Input:  "中文(text)中文"
Output: "中文（text）中文"

Input:  "中文。。。中文"
Output: "中文……中文"
```

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
