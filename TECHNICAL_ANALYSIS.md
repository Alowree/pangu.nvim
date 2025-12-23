# Pangu.nvim - Complete Technical Analysis

## Project Overview

**pangu.nvim** is a Neovim plugin that enhances text formatting for CJK (Chinese, Japanese, Korean) content. It automatically:

- Adds spacing between CJK and English/digits
- Converts English punctuation to Chinese equivalents
- Normalizes formatting while preserving code blocks

**Repository:** `/Users/alowree/Desktop/pangu.nvim`

---

## Architecture & Module Structure

```
pangu.nvim/
├── lua/pangu/
│   ├── init.lua             ← Plugin entry point & API
│   ├── config.lua           ← Configuration management
│   ├── processor.lua        ← Core formatting logic (421 lines)
│   ├── tokenizer.lua        ← Text tokenization & classification
│   └── utils.lua            ← Character detection utilities
├── plugin/                  ← Vim plugin initialization
├── tests/
│   └── test_processor.lua   ← Comprehensive unit tests
└── README.md
```

### Module Dependencies

```
init.lua
  ├── config.lua
  └── processor.lua
       ├── tokenizer.lua
       └── utils.lua
```

---

## Core Formatting Pipeline

### 1. Text Tokenization (`tokenizer.lua`)

```lua
-- Split UTF-8 aware
text → split_utf8() → array of UTF-8 characters

-- Classify each token
tokens → classify_token() for each
  ├── CHINESE (CJK range: U+4E00-U+9FFF, etc.)
  ├── ENGLISH (a-zA-Z)
  ├── DIGIT (0-9)
  ├── WHITESPACE
  ├── PUNCTUATION
  ├── MARKDOWN_CODE (`)
  ├── MARKDOWN_BOLD (*, _)
  ├── MARKDOWN_LINK ([, ], (, ))
  └── OTHER
```

**Key Functions:**

- `split_utf8(text)` - Correctly handles multi-byte UTF-8 characters
- `classify_token(token)` - Assigns token type
- `tokenize(text)` - Returns array of `{token, type}` pairs

### 2. Character Detection (`utils.lua`)

**Classification Functions:**

- `is_chinese(char)` - Checks CJK Unicode ranges
- `is_english_or_digit(char)` - ASCII alphanumeric check
- `is_whitespace(char)` - Space/tab/newline check
- `is_chinese_punctuation(char)` - Checks Chinese punct marks

**Conversion Tables:**

- `punct_map` - English → Chinese punctuation mapping
- `paren_map` - English → Chinese parenthesis mapping
- `quote_map` - ASCII → Chinese quote mapping
- `dedup_chars` - Characters to deduplicate

### 3. Text Processing (`processor.lua`)

**Processing Chain:**

```
Input Text
    ↓
[1] add_space_between_cjk_and_english()
    │ "中文English中文" → "中文 English 中文"
    ↓
[2] add_space_between_cjk_and_digit()
    │ "中文123中文" → "中文 123 中文"
    ↓
[3] add_space_around_markdown()
    │ "中文`code`中文" → "中文 `code` 中文"
    ↓
[4] convert_punctuation()
    │ "中文," → "中文，"
    ↓
[5] convert_parentheses()
    │ "中文(注)" → "中文（注）"
    ↓
[6] convert_quotes()
    │ '中文"引"中文' → '中文"引"中文'
    ↓
[7] normalize_repeated_marks()
    │ "中文。。。" → "中文。"
    ↓
Output Text
```

**Each step is controlled by config flags:**

- `enable_spacing` (affects steps 1-3)
- `enable_punct_convert` (step 4)
- `enable_paren_convert` (step 5)
- `enable_quote_convert` (step 6)
- `enable_dedup_marks` (step 7)

---

## Code Block Handling (THE BUG & FIX)

### The Problem

The plugin was designed to **skip formatting inside Markdown code blocks** (` ``` `) when `skip_code_blocks = true`, but unit tests were failing.

### Root Cause: Lua Pattern Syntax

**Broken Code:**

```lua
local function is_code_block_fence(line)
    return line:match("^%s*`{3,}") ~= nil
end
```

**The Issue:**
In **Lua pattern matching**, `{3,}` is NOT a quantifier operator (unlike PCRE/regex). It's treated as literal characters to match.

**Pattern Analysis:**

- `^%s*` ✓ Correct (start + optional whitespace)
- `` ` `` ✓ Correct (backtick)
- `{3,}` ✗ **WRONG** - Looks for literal `{3,}` characters

### The Solution

**Fixed Code:**

```lua
local function is_code_block_fence(line)
    return line:match("^%s*`%`%`%`*") ~= nil
end
```

**Correct Pattern Breakdown:**

- `^` = Start of line
- `%s*` = Zero or more whitespace
- `` %` `` = Literal backtick (escaped with %)
- `` %` `` = Literal backtick (escaped with %)
- `` %` `` = Literal backtick (escaped with %)
- `` %`* `` = Zero or more additional backticks

**What It Matches:**

- ✅ ` ``` ` (3 backticks)
- ✅ ` ```` ` (4 backticks)
- ✅ `  ```` (with leading spaces)
- ❌ ` foo```bar ` (not at start)
- ❌ ` ` `` (only 2 backticks)

### Code Block State Machine

When `skip_code_blocks = true`, the `format_buffer()` function:

```lua
local in_code_block = false

for i, line in ipairs(lines) do
    if is_code_block_fence(line) then
        -- Fence line: output as-is, toggle state
        lines[i] = line
        in_code_block = not in_code_block  -- true ↔ false

    elseif in_code_block then
        -- Inside code block: skip formatting
        lines[i] = line

    else
        -- Outside code block: apply all formatting rules
        lines[i] = M.format(line)
    end
end
```

**Example:**

````
Input:
  中文English          ← Line 1
  ```               ← Fence (toggle to in_code_block=true)
  中文English        ← Line 3 (inside code block)
  ```               ← Fence (toggle to in_code_block=false)
  中文English        ← Line 5

Processing:
  Line 1: in_code_block=false → FORMAT → "中文 English"
  Line 2: Fence → toggle to true, output "```" as-is
  Line 3: in_code_block=true → SKIP → "中文English" (unchanged)
  Line 4: Fence → toggle to false, output "```" as-is
  Line 5: in_code_block=false → FORMAT → "中文 English"

Output:
  中文 English
````

中文 English ← Preserved!

```
中文 English
```

---

## Configuration System

**File:** `lua/pangu/config.lua`

````lua
M.defaults = {
    -- Feature toggles
    enable_spacing = true,              -- CJK-English/Digit spacing
    enable_punct_convert = true,        -- Punctuation conversion
    enable_paren_convert = true,        -- Parenthesis conversion
    enable_quote_convert = true,        -- Quote conversion
    enable_dedup_marks = true,          -- Duplicate mark removal

    -- Auto-formatting
    enable_on_save = true,              -- Format on file save
    file_patterns = { "*.md", "*.txt", "*.norg" },

    -- Markdown-specific
    skip_code_blocks = true,            -- Skip content inside ```
    add_space_around_markdown = true,   -- Space around code/bold/links
}
````

**API:**

```lua
pangu.setup(opts)        -- Initialize with options
pangu.config.get(key)    -- Get a setting
pangu.config.set(key, val) -- Set a setting
```

---

## Testing

**File:** `tests/test_processor.lua`

### Test Coverage

**Basic Formatting (16 tests):**

- ✅ CJK-English spacing
- ✅ CJK-Digit spacing
- ✅ Markdown element spacing (code, bold, links)
- ✅ Punctuation conversion
- ✅ Parenthesis conversion
- ✅ Quote conversion (single & double)
- ✅ Duplicate punctuation removal

**Code Block Skipping (2 tests):**

- ✅ Skip enabled: Lines inside ` ` are NOT formatted
- ✅ Skip disabled: All lines ARE formatted

### Running Tests

```bash
cd /Users/alowree/Desktop/pangu.nvim
lua tests/test_processor.lua
```

**Expected Output:**

```
--- Code Block Skipping Tests ---
[OK] Code block test: Skip formatting inside code blocks when enabled
[OK] Code block test: Format inside code blocks when skip disabled
[OK] CJK <-> English spacing
[OK] CJK <-> Digit spacing
... (all 18 tests should pass)

All tests passed
```

---

## File-by-File Breakdown

### `init.lua` - Plugin Entry Point

- Exports `setup()`, `format()`, `config` module
- Main API surface for users

### `config.lua` - Configuration Management

- Stores configuration state
- Provides `setup()`, `get()`, `set()` methods
- Integrates with Neovim's `vim.deepcopy()` and `vim.tbl_deep_extend()`

### `processor.lua` - Core Logic (421 lines)

**Public Functions:**

- `format(text)` - Main formatting function
- `format_buffer(bufnr)` - Format entire buffer with code block awareness
- `format_range(bufnr, start, end)` - Format range with code block awareness

**Private Functions:**

- `add_space_between_cjk_and_english(text)` - Spacing logic
- `add_space_between_cjk_and_digit(text)` - Spacing logic
- `add_space_around_markdown(text)` - Markdown spacing
- `convert_punctuation(text)` - Punct conversion
- `convert_parentheses(text)` - Paren conversion
- `convert_quotes(text)` - Quote conversion
- `normalize_repeated_marks(text)` - Deduplication
- `is_code_block_fence(line)` - **FIXED FUNCTION**

### `tokenizer.lua` - Tokenization (105 lines)

**Token Types:**

```lua
TokenType = {
    CHINESE = 1,
    ENGLISH = 2,
    DIGIT = 3,
    WHITESPACE = 4,
    PUNCTUATION = 5,
    MARKDOWN_CODE = 6,
    MARKDOWN_BOLD = 7,
    MARKDOWN_LINK = 8,
    OTHER = 9,
}
```

**Functions:**

- `split_utf8(text)` - UTF-8 aware splitting
- `classify_token(token)` - Type assignment
- `tokenize(text)` - Returns `{token, type}` array

### `utils.lua` - Character Detection (107 lines)

**Detection Functions:**

- `is_chinese(char)` - CJK Unicode ranges
- `is_english_or_digit(char)` - ASCII check
- `is_whitespace(char)` - Space check
- `is_chinese_punctuation(char)` - Chinese punct check

**Mappings:**

- `punct_map` - Comma, period, question, etc.
- `paren_map` - Parenthesis conversion
- `quote_map` - Quote conversion
- `dedup_chars` - Characters to normalize

---

## Lua Pattern Reference

For understanding the fix and debugging:

| Pattern | Meaning    | Example                         |
| ------- | ---------- | ------------------------------- |
| `.`     | Any char   | `a.c` matches `abc`             |
| `%a`    | Letter     | `%a+` matches words             |
| `%d`    | Digit      | `%d{3}` matches literal `{3}` ✗ |
| `%s`    | Space      | `%s*` matches spaces            |
| `%w`    | Word char  | `%w+` matches word              |
| `*`     | 0+ times   | `a*` matches 0+ `a`             |
| `+`     | 1+ times   | `a+` matches 1+ `a`             |
| `-`     | 0+ (lazy)  | `a-` matches minimal `a`        |
| `?`     | 0-1 times  | `a?` matches 0 or 1 `a`         |
| `[...]` | Char class | `[abc]` matches a/b/c           |
| `^`     | Start      | `^x` matches x at start         |
| `$`     | End        | `x$` matches x at end           |

**Lua DOES NOT Support:**

- ❌ `\d`, `\w`, `\s` (use `%d`, `%w`, `%s` instead)
- ❌ `{n}`, `{n,}`, `{n,m}` (quantifiers don't exist!)
- ❌ `\b`, lookahead, lookbehind, etc.

---

## Key Learnings

1. **UTF-8 Handling**: Lua's `string` module is byte-oriented; the plugin correctly uses multi-byte aware character counting

2. **Lua Patterns vs Regex**: Common regex syntax (like `{3,}`) doesn't work in Lua; must use explicit character repetition

3. **Tokenization Strategy**: Breaking text into tokens and classifying allows precise control over spacing rules

4. **State Machine**: Code block tracking uses simple boolean state toggle on fence detection

5. **Configuration Flexibility**: Each formatting rule can be toggled independently via config

---

## Summary Table

| Aspect              | Details                                          |
| ------------------- | ------------------------------------------------ |
| **Language**        | Lua (Neovim plugin)                              |
| **Purpose**         | CJK text formatting and spacing                  |
| **Main Bug**        | Lua pattern `{3,}` syntax not supported          |
| **Fix Location**    | `processor.lua#355` and `test_processor.lua#119` |
| **Pattern Changed** | `^%s*`{3,}`→`^%s*`%`%`%`%`*`                     |
| **Tests**           | 18 total (16 formatting + 2 code block)          |
| **Status**          | ✅ All tests passing after fix                   |

---

## Files Modified in This Session

```
/Users/alowree/Desktop/pangu.nvim/
├── lua/pangu/processor.lua          ← FIXED
├── tests/test_processor.lua         ← FIXED
├── FORMATTING_ANALYSIS.md           ← NEW (comprehensive analysis)
├── BUG_FIX_REPORT.md               ← NEW (detailed fix explanation)
└── CODE_BLOCK_REFERENCE.lua        ← NEW (quick reference guide)
```

---

**Created:** December 23, 2025  
**Status:** ✅ Complete - Bug identified, fixed, and documented
