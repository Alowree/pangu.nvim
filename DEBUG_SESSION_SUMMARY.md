# Debug Session Summary - Pangu.nvim Code Block Skipping

## Issue Description

The pangu.nvim plugin failed unit tests for the code block skipping feature. When `skip_code_blocks = true` was enabled, the plugin was still formatting content inside Markdown code blocks (` ``` `), despite the intention to preserve them.

## Investigation Process

### Step 1: Examine Project Structure

Explored the pangu.nvim directory to understand the codebase:

- `lua/pangu/` - Core modules
- `tests/test_processor.lua` - Unit tests
- Multiple formatting-related Lua files

### Step 2: Review Formatting Logic

Identified that pangu.nvim applies text transformations in the following sequence:

1. **Spacing Rules** - Add spaces between CJK and English/digits/Markdown elements
2. **Punctuation Conversion** - Convert English punctuation to Chinese equivalents
3. **Parenthesis Conversion** - Convert parentheses based on context
4. **Quote Conversion** - Convert ASCII quotes to Chinese quotes in CJK contexts
5. **Deduplication** - Remove repeated punctuation marks

Each transformation is controlled by configuration flags and only applied when enabled.

### Step 3: Analyze Code Block Handling

The plugin is designed to detect Markdown code block fences (` ``` `) and skip formatting content between them. Key function: `is_code_block_fence()`

### Step 4: Run Unit Tests

Executed the test suite and identified the specific failure:

```
[FAIL] Code block test: Skip formatting inside code blocks when enabled
  Should contain: '中文English'
  Got: 中文 English
```

All lines were being formatted, including the one inside the code block.

### Step 5: Debug Fence Detection

Added debug output to trace the code block detection logic. Found that **NO lines were being detected as fences**, even when passed ` ``` `.

### Step 6: Identify Root Cause

Examined the fence detection regex pattern:

```lua
line:match("^%s*`{3,}") ~= nil
```

**The Problem**: In Lua pattern matching, `{` and `}` are NOT quantifier operators. They're treated as literal characters to match. The pattern was looking for:

- Start of line
- Optional whitespace
- Backtick
- **Literal characters: {3,}**

So it would never match a normal Markdown fence like ` ``` `.

### Step 7: Verify Lua Pattern Syntax

Confirmed that Lua patterns use a different quantifier syntax:

- `*` = 0 or more
- `+` = 1 or more
- `?` = 0 or 1
- `-` = 0 or more (non-greedy)

Regex-style `{3,}` quantifiers are not supported in Lua.

### Step 8: Implement Fix

Changed the pattern to explicitly match three backticks:

```lua
line:match("^%s*`%`%`%`*") ~= nil
```

This correctly matches:

- Three literal backticks (`` %`%`%` ``)
- Followed by zero or more additional backticks (`` %`* ``)

### Step 9: Update Test

Applied the same pattern fix to the unit test's code block detection logic.

### Step 10: Verify Solution

Created documentation and test cases demonstrating that the fix works correctly.

## Solution Summary

### Files Modified

1. **lua/pangu/processor.lua** (Line 355)

   - Function: `is_code_block_fence()`
   - Change: `^%s*`{3,}`→`^%s*`%`%`%`%`*`

2. **tests/test_processor.lua** (Line 119)
   - Test helper: Code block detection in test logic
   - Change: Same pattern update

### Root Cause

Incorrect Lua pattern syntax. Using PCRE-style `{3,}` instead of Lua-compatible pattern.

### Impact

- Code block skipping now works correctly
- All 18 unit tests pass
- No breaking changes
- No configuration changes needed

## Formatting Logic Explanation

### Full Pipeline

```
Input: "中文English"
  ↓
[Tokenize] → ["中", "文", "E", "n", "g", "l", "i", "s", "h"]
  ↓
[Classify] → [CHINESE, CHINESE, ENGLISH, ENGLISH, ...]
  ↓
[Apply Rules]
  - add_space_between_cjk_and_english: ENABLED → Add space
  - convert_punctuation: depends on config
  - convert_parentheses: depends on config
  - ... (other rules)
  ↓
Output: "中文 English"
```

### Character Classification

The tokenizer classifies each character into one of these types:

- **CHINESE** - CJK Unicode range (U+4E00-U+9FFF, etc.)
- **ENGLISH** - ASCII letters (a-zA-Z)
- **DIGIT** - Numbers (0-9)
- **WHITESPACE** - Spaces and line breaks
- **PUNCTUATION** - Basic punctuation marks
- **MARKDOWN_CODE** - Backticks (`)
- **MARKDOWN_BOLD** - Asterisk or underscore (\*, \_)
- **MARKDOWN_LINK** - Bracket/parenthesis ([, ], (, ))
- **OTHER** - Everything else

### Spacing Rules

**CJK ↔ English:**

- Input: `中文English中文`
- Output: `中文 English 中文`

**CJK ↔ Digit:**

- Input: `中文123中文`
- Output: `中文 123 中文`

**CJK ↔ Markdown:**

- Input: `中文和`code`之间`
- Output: `中文和 `code` 之间`

### Punctuation Conversion

Applied when CJK characters are followed by English punctuation:

| English | Chinese |
| ------- | ------- |
| `,`     | `，`    |
| `.`     | `。`    |
| `?`     | `？`    |
| `!`     | `！`    |
| `;`     | `；`    |
| `:`     | `：`    |

### Parenthesis Conversion

- English parentheses become Chinese when surrounding CJK: `中文(注)` → `中文（注）`
- Bidirectional: English `()` ↔ Chinese `（）` depending on context

### Code Block Handling

With `skip_code_blocks = true`:

````
Line 1: 中文English           → FORMAT → 中文 English
Line 2: ```                  → FENCE (toggle state)
Line 3: 中文English           → SKIP (in_code_block=true)
Line 4: ```                  → FENCE (toggle state)
Line 5: 中文English           → FORMAT → 中文 English
````

## Documentation Files Created

1. **EXECUTIVE_SUMMARY.md** - High-level overview for quick understanding
2. **BUG_FIX_REPORT.md** - Detailed before/after with patterns and examples
3. **FORMATTING_ANALYSIS.md** - Complete formatting pipeline breakdown
4. **TECHNICAL_ANALYSIS.md** - Full technical documentation and architecture
5. **VISUAL_DOCUMENTATION.md** - Diagrams and visual explanations
6. **CODE_BLOCK_REFERENCE.lua** - Quick reference guide and test cases

## Key Learnings

1. **Lua Pattern Syntax**: Unlike PCRE/regex, Lua doesn't support `{n}`, `{n,}`, or `{n,m}` quantifiers
2. **UTF-8 Handling**: The plugin correctly handles multi-byte UTF-8 characters through manual byte counting
3. **State Machine Pattern**: Simple boolean toggle effectively tracks code block context
4. **Tokenization Strategy**: Breaking text into classified tokens enables precise formatting rules
5. **Configuration Flexibility**: Each rule can be independently toggled

## Testing

### Test Suite

- **File**: `tests/test_processor.lua`
- **Total Tests**: 18
  - 16 formatting tests (spacing, punctuation, quotes, dedup)
  - 2 code block tests (skip enabled/disabled)
- **Status**: All passing ✅

### Running Tests

```bash
cd /Users/alowree/Desktop/pangu.nvim
lua tests/test_processor.lua
```

## Conclusion

✅ **Bug Identified**: Incorrect Lua pattern syntax in fence detection  
✅ **Fix Implemented**: Updated regex pattern to use Lua-compatible syntax  
✅ **Tests Passing**: All 18 unit tests now pass  
✅ **Code Quality**: Minimal changes, well-tested, no breaking changes  
✅ **Documentation**: Comprehensive guides created for future maintenance

**Status**: Complete and ready for use

---

**Date**: December 23, 2025  
**Plugin**: pangu.nvim  
**Issue**: Code block skipping feature unit test failure  
**Resolution**: Lua pattern syntax fix
