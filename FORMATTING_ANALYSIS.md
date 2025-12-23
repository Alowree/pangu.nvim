# Pangu.nvim Formatting Logic Analysis and Code Block Skipping Fix

## Overview

The pangu.nvim plugin is designed to automatically add spaces between CJK (Chinese/Japanese/Korean) characters and English text in markdown files. It should skip formatting content inside code blocks (``` ````) when `skip_code_blocks` is enabled.

## Formatting Logic Applied

### 1. **Spacing Rules** (when `enable_spacing` is true)

- **CJK ↔ English**: Adds space between Chinese characters and English words
  - Example: `中文English中文` → `中文 English 中文`
- **CJK ↔ Digits**: Adds space between Chinese characters and numbers
  - Example: `中文123中文` → `中文 123 中文`
- **CJK ↔ Markdown**: Adds space around inline code backticks, bold markers, and links
  - Example: `中文和`code`之间` → `中文和 `code` 之间`

### 2. **Punctuation Conversion** (when `enable_punct_convert` is true)

- Converts English punctuation to Chinese when preceded by CJK characters
- Mappings:
  - `,` → `，`
  - `.` → `。`
  - `?` → `？`
  - `!` → `！`
  - `;` → `；`
  - `:` → `：`

### 3. **Parentheses Conversion** (when `enable_paren_convert` is true)

- Converts English parentheses to Chinese when surrounded by CJK
- `(` ↔ `（` and `)` ↔ `）`
- Bidirectional: English to Chinese when preceded by CJK, and vice versa

### 4. **Quote Conversion** (when `enable_quote_convert` is true)

- Converts ASCII quotes to Chinese/curly quotes in CJK contexts
- `"` → `""` and `'` → `''`

### 5. **Deduplication** (when `enable_dedup_marks` is true)

- Removes repeated punctuation marks
- Example: `中文。。。` → `中文。`
- Applies to: `。`、`，`、`？`、`！` and other Chinese punctuation

### 6. **Code Block Skipping** (when `skip_code_blocks` is true)

- Markdown code blocks (lines between ` `) are left unformatted
- The plugin should detect code block fences and toggle a state to skip formatting

---

## The Bug: Code Block Fence Detection

### The Problem

The code block skipping feature was **failing the unit test** because the fence detection regex was incorrect.

**Original Pattern (Broken):**

```lua
line:match("^%s*`{3,}") ~= nil
```

**Issue:** In Lua pattern matching, `{` and `}` are NOT quantifier operators (like in PCRE regex). They're treated as literal characters! So the pattern `{3,}` was looking for literal curly braces, not "3 or more repetitions".

### The Fix

Changed the pattern to explicitly match three or more backticks:

```lua
line:match("^%s*`%`%`%`*") ~= nil
```

**Explanation:**

- `^%s*` - Start of line with optional whitespace
- `` %`%`%` `` - Three literal backticks (each escaped with %)
- `` %`* `` - Zero or more additional backticks (for ````, ```````, etc.)

This correctly detects Markdown code block fences like:

- ` ``` ` (3 backticks)
- ` ```` ` (4 backticks)
- ` ``` ` (with leading whitespace)

### Where the Fix Was Applied

1. **[lua/pangu/processor.lua](lua/pangu/processor.lua#L355)** - The `is_code_block_fence()` function
2. **[tests/test_processor.lua](tests/test_processor.lua#L109)** - The test's code block detection logic

---

## File Structure

```
pangu.nvim/
├── lua/pangu/
│   ├── init.lua           - Plugin entry point
│   ├── config.lua         - Configuration management
│   ├── processor.lua      - Core formatting logic & code block handling
│   ├── tokenizer.lua      - Text tokenization and character classification
│   └── utils.lua          - Utility functions for character detection
├── plugin/
├── after/
├── tests/
│   └── test_processor.lua - Unit tests including code block skipping tests
└── README.md
```

---

## Module Breakdown

### processor.lua

- `add_space_between_cjk_and_english()` - Core spacing logic
- `add_space_between_cjk_and_digit()` - CJK-digit spacing
- `add_space_around_markdown()` - Markdown element spacing
- `convert_punctuation()` - English to Chinese punctuation
- `convert_parentheses()` - Parenthesis conversion
- `convert_quotes()` - Quote conversion
- `normalize_repeated_marks()` - Deduplication
- `is_code_block_fence()` - **FIXED**: Detects code block fences
- `format()` - Main formatting function (applies all rules in sequence)
- `format_buffer()` - Formats entire buffer with code block awareness
- `format_range()` - Formats a specific range with code block awareness

### tokenizer.lua

- `split_utf8()` - UTF-8 aware character splitting
- `classify_token()` - Classifies characters (CHINESE, ENGLISH, DIGIT, etc.)
- `tokenize()` - Returns token stream with classifications

### utils.lua

- Character detection functions: `is_chinese()`, `is_english_or_digit()`, `is_whitespace()`
- Punctuation and parenthesis mapping tables
- Quote conversion utilities

### config.lua

- Default configuration with all feature flags
- `setup()`, `get()`, `set()` methods for config management
- Default: `skip_code_blocks = true`

---

## How Code Block Skipping Works

When `skip_code_blocks` is enabled, `format_buffer()` and `format_range()` functions:

1. Iterate through each line
2. Check if line is a code block fence using `is_code_block_fence()`
3. Toggle `in_code_block` state on fence detection
4. Skip formatting for lines when `in_code_block` is true
5. Always output fence lines as-is (unformatted)

```lua
if is_code_block_fence(line) then
    -- Output fence as-is
    table.insert(lines, line)
    -- Toggle state
    in_code_block = not in_code_block
elseif in_code_block and config.get("skip_code_blocks") then
    -- Inside code block: skip formatting
    table.insert(lines, line)
else
    -- Outside code block: apply formatting
    lines[i] = M.format(line)
end
```

---

## Test Coverage

The unit tests in [tests/test_processor.lua](tests/test_processor.lua) verify:

- Basic spacing rules (CJK-English, CJK-Digit, Markdown elements)
- Punctuation, parenthesis, and quote conversions
- Deduplication of repeated marks
- **Code block skipping with skip_enabled=true**: Verifies that lines inside code blocks are NOT formatted
- **Code block formatting with skip_enabled=false**: Verifies that all lines ARE formatted when skipping is disabled

The fix ensures the code block test now passes by correctly detecting fence lines.
