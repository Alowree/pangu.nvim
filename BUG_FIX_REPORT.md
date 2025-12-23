# Pangu.nvim Code Block Skipping - Bug Fix Summary

## Problem Identified

The code block skipping feature was **failing unit tests** because the Markdown code fence detection regex pattern was incorrect for Lua.

### Root Cause

**Lua pattern matching does NOT support `{n,m}` quantifier syntax** like PCRE regex. The pattern `{3,}` is interpreted as literal characters to match, not as a "3 or more" quantifier.

**Broken Code:**

```lua
line:match("^%s*`{3,}") ~= nil
```

This pattern tried to match literal `{3,}` characters after the backticks, which would never occur in normal Markdown code blocks.

---

## Solution Applied

### 1. **processor.lua** - Main Plugin File

**Location:** [lua/pangu/processor.lua#L355](lua/pangu/processor.lua#L355)

**Before:**

`````lua
-- Check if a line is a code block fence (``` or ````)
local function is_code_block_fence(line)
	return line:match("^%s*`{3,}") ~= nil
end
`````

**After:**

`````lua
-- Check if a line is a code block fence (``` or ````)
-- Lua patterns don't support {3,} quantifiers, so match 3+ backticks as ```*
local function is_code_block_fence(line)
	return line:match("^%s*`%`%`%`*") ~= nil
end
`````

**Pattern Explanation:**

- `^` - Start of line
- `%s*` - Zero or more whitespace characters
- `` %`%`%` `` - Exactly three literal backticks (each escaped with `%`)
- `` %`* `` - Zero or more additional backticks (for 4, 5, or more backticks)

This correctly matches:

- ` ``` ` → ✓ Matches (3 backticks)
- ` ```` ` → ✓ Matches (4 backticks)
- ` ``` ` → ✓ Matches (leading whitespace)
- ` foo```bar ` → ✗ Doesn't match (not at start)
- `` `  `` `` → ✗ Doesn't match (only 2 backticks)

---

### 2. **test_processor.lua** - Unit Tests

**Location:** [tests/test_processor.lua#L119](tests/test_processor.lua#L119)

**Before:**

```lua
-- Check if this line is a code block fence
if line:match("^%s*`{3,}") then
```

**After:**

````lua
-- Check if this line is a code block fence - in Lua patterns, match 3+ backticks as ```*
if line:match("^%s*`%`%`%`*") then
````

---

## How Code Block Skipping Works

When processing a file with `skip_code_blocks = true`:

````
Input:
  Line 1: 中文English                    → FORMAT → 中文 English
  Line 2: ```                            → FENCE (toggle state)
  Line 3: 中文English                    → SKIP (inside code block)
  Line 4: ```                            → FENCE (toggle state)
  Line 5: 中文English                    → FORMAT → 中文 English

Output:
  中文 English
````

中文 English ← Unformatted!

```
中文 English
```

**State Machine Logic (in `format_buffer()`):**

```lua
local in_code_block = false

for i, line in ipairs(lines) do
    if is_code_block_fence(line) then
        -- Fence line: output as-is and toggle state
        lines[i] = line
        in_code_block = not in_code_block
    elseif in_code_block and config.get("skip_code_blocks") then
        -- Inside code block with skip enabled: don't format
        lines[i] = line
    else
        -- Outside code block or skip disabled: apply formatting
        lines[i] = M.format(line)
    end
end
```

---

## Test Results

### Code Block Skipping Test Cases

1. **Skip Enabled (`skip_code_blocks = true`)**

   - Line inside code block should remain unformatted
   - Lines outside code block should be formatted
   - Test checks for presence of unformatted `中文English` AND formatted `中文 English`
   - **Status:** ✅ PASS (after fix)

2. **Skip Disabled (`skip_code_blocks = false`)**
   - All lines should be formatted regardless of code block fences
   - Test checks that no unformatted `中文English` exists
   - **Status:** ✅ PASS

### Other Formatting Tests

All other tests continue to pass:

- ✅ CJK ↔ English spacing
- ✅ CJK ↔ Digit spacing
- ✅ Markdown element spacing (code, bold, links)
- ✅ Punctuation conversion
- ✅ Parenthesis conversion
- ✅ Quote conversion
- ✅ Repeated punctuation deduplication

---

## Files Modified

| File                                                 | Change                                                  |
| ---------------------------------------------------- | ------------------------------------------------------- |
| [lua/pangu/processor.lua](lua/pangu/processor.lua)   | Fixed regex pattern in `is_code_block_fence()` function |
| [tests/test_processor.lua](tests/test_processor.lua) | Updated test to use correct fence detection pattern     |

---

## Lua Pattern Reference

For future reference, here are common Lua pattern constructs:

| Pattern  | Meaning                  |
| -------- | ------------------------ |
| `.`      | Any character            |
| `%a`     | Letter                   |
| `%d`     | Digit                    |
| `%s`     | Whitespace               |
| `%w`     | Word char (letter/digit) |
| `*`      | 0 or more (of preceding) |
| `+`      | 1 or more (of preceding) |
| `-`      | 0 or more (non-greedy)   |
| `?`      | 0 or 1 (of preceding)    |
| `^`      | Start of string          |
| `$`      | End of string            |
| `[abc]`  | Character class          |
| `[^abc]` | Negated character class  |

**Key Difference from PCRE:**

- ❌ Lua does NOT support: `{n}`, `{n,}`, `{n,m}`, `\b`, `\d`, `\w`, etc.
- ✅ Use Lua-specific patterns instead: `%d`, `%w`, `%a`, `%s`, etc.

---

## Configuration

The `skip_code_blocks` feature is controlled by the config:

````lua
-- Default configuration (lua/pangu/config.lua)
M.defaults = {
    skip_code_blocks = true,  -- Skip formatting inside ``` ``` blocks
    -- ... other settings
}
````

Users can override this in their setup:

```lua
require("pangu").setup({
    skip_code_blocks = false  -- Disable code block skipping if desired
})
```

---

## Summary

✅ **Bug:** Lua pattern `{3,}` was treated as literal characters, not a quantifier  
✅ **Fix:** Use Lua-compatible pattern `` %`%`%`%`* `` to match 3+ backticks  
✅ **Result:** Code block skipping now works correctly, unit tests pass  
✅ **Impact:** No breaking changes; all existing formatting features continue to work
