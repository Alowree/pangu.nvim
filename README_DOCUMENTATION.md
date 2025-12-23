# Pangu.nvim Documentation Index

## 📋 Quick Links

### For Quick Understanding

- **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** ⭐ START HERE
  - 5-minute overview of the bug and fix
  - Perfect for quick understanding

### For Debugging & Implementation

- **[BUG_FIX_REPORT.md](BUG_FIX_REPORT.md)** 🐛
  - Detailed before/after code comparison
  - Pattern explanation with examples
  - Root cause analysis

### For Architecture & Design

- **[TECHNICAL_ANALYSIS.md](TECHNICAL_ANALYSIS.md)** 🏗️
  - Complete module breakdown
  - Processing pipeline details
  - Configuration system
  - Testing information

### For Learning & Reference

- **[FORMATTING_ANALYSIS.md](FORMATTING_ANALYSIS.md)** 📚

  - Comprehensive formatting pipeline
  - Feature-by-feature breakdown
  - How the plugin works step-by-step

- **[VISUAL_DOCUMENTATION.md](VISUAL_DOCUMENTATION.md)** 📊
  - Diagrams and visual flows
  - ASCII diagrams of the state machine
  - File organization chart
  - Character classification reference

### For Session Context

- **[DEBUG_SESSION_SUMMARY.md](DEBUG_SESSION_SUMMARY.md)** 📝
  - Complete debugging process walkthrough
  - Step-by-step investigation
  - Testing process documented

### Quick Reference

- **[CODE_BLOCK_REFERENCE.lua](CODE_BLOCK_REFERENCE.lua)** ⚡
  - Runnable Lua reference
  - Pattern testing examples
  - Configuration snippets

---

## 🔧 The Bug in One Sentence

Lua pattern syntax `{3,}` doesn't mean "3 or more" — it's literal characters. The code block fence detection was broken.

---

## ✅ The Fix in One Sentence

Changed `^%s*`{3,}`to`^%s*`%`%`%`%`*` to match Markdown code block fences using Lua-compatible pattern syntax.

---

## 📁 Project Structure

```
pangu.nvim/
├── lua/pangu/
│   ├── init.lua              ← Entry point
│   ├── config.lua            ← Configuration
│   ├── processor.lua         ← [FIXED] Core logic, line 355
│   ├── tokenizer.lua         ← Text tokenization
│   └── utils.lua             ← Utilities
├── tests/
│   └── test_processor.lua    ← [FIXED] Unit tests, line 119
└── Documentation/
    ├── EXECUTIVE_SUMMARY.md
    ├── BUG_FIX_REPORT.md
    ├── FORMATTING_ANALYSIS.md
    ├── TECHNICAL_ANALYSIS.md
    ├── VISUAL_DOCUMENTATION.md
    ├── CODE_BLOCK_REFERENCE.lua
    ├── DEBUG_SESSION_SUMMARY.md
    └── README.md (this file)
```

---

## 🎯 Files Modified

| File                       | Line | Change                                |
| -------------------------- | ---- | ------------------------------------- |
| `lua/pangu/processor.lua`  | 355  | Pattern: `^%s*`{3,}`→`^%s*`%`%`%`%`*` |
| `tests/test_processor.lua` | 119  | Same pattern update                   |

---

## 🧪 Test Results

**Before Fix**: 1 test failed (code block skipping)  
**After Fix**: All 18 tests pass ✅

```
✅ Code block test: Skip formatting inside code blocks when enabled
✅ Code block test: Format inside code blocks when skip disabled
✅ CJK <-> English spacing
✅ CJK <-> Digit spacing
✅ CJK and inline code spacing
✅ CJK and bold spacing
✅ CJK and link spacing
✅ Comma converted
✅ Period converted
✅ Question mark converted
✅ Exclamation mark converted
✅ Parentheses converted
✅ Double quote converted
✅ Single quote converted
✅ Truncate repeated ，
✅ Truncate repeated 。
✅ Truncate repeated ？
✅ Truncate repeated ！
```

---

## 🔍 What This Plugin Does

The pangu.nvim plugin automatically formats text with CJK (Chinese/Japanese/Korean) characters:

### Spacing

- `中文English` → `中文 English`
- `中文123` → `中文 123`

### Punctuation

- `中文,` → `中文，`
- `中文.` → `中文。`

### Parentheses

- `中文(note)` → `中文（note）`

### Code Blocks (NEW FEATURE - NOW FIXED)

- Content inside ` ``` ` ``is preserved when`skip_code_blocks = true`

---

## 📖 Documentation Levels

### Level 1: 5-Minute Read

→ Start with **EXECUTIVE_SUMMARY.md**

### Level 2: 15-Minute Read

→ Then read **BUG_FIX_REPORT.md**

### Level 3: 30-Minute Read

→ Continue with **TECHNICAL_ANALYSIS.md**

### Level 4: Deep Dive

→ Study all files in order for complete understanding

---

## 🎓 Key Concepts

### Lua Patterns (NOT Regex)

| Concept         | Lua    | Regex  |
| --------------- | ------ | ------ |
| 0+ repetitions  | `*`    | `*`    |
| 1+ repetitions  | `+`    | `+`    |
| 0-1 repetitions | `?`    | `?`    |
| N repetitions   | ❌ N/A | `{n}`  |
| N+ repetitions  | ❌ N/A | `{n,}` |

**Key Takeaway**: Lua doesn't support regex quantifiers like `{3,}`

### Code Block State Machine

```
Enabled (skip_code_blocks = true):
  [outside] ──fence──► [inside] ──fence──► [outside]
     format             skip                 format

Disabled (skip_code_blocks = false):
  [state toggled but formatting applied always]
     format             format               format
```

### Character Classification

The plugin classifies each character to apply rules intelligently:

- CHINESE (CJK Unicode ranges)
- ENGLISH (ASCII letters)
- DIGIT (Numbers)
- WHITESPACE (Spaces)
- PUNCTUATION (., ,, !, ?)
- MARKDOWN (code, bold, links)
- OTHER (everything else)

---

## 🔗 Related Information

### Neovim Plugin Development

- Plugin structure: `/plugin/` folder
- Lua modules: `/lua/` folder
- Config system: Uses Neovim's `vim.deepcopy()` and `vim.tbl_deep_extend()`

### UTF-8 Handling

The plugin correctly handles multi-byte UTF-8 characters by:

- Manual byte counting instead of simple indexing
- Proper character detection for CJK ranges

### Configuration

Users can enable/disable features individually:

```lua
require("pangu").setup({
    enable_spacing = true,           -- CJK-English spacing
    enable_punct_convert = true,     -- Punctuation conversion
    enable_paren_convert = true,     -- Parenthesis conversion
    enable_quote_convert = true,     -- Quote conversion
    enable_dedup_marks = true,       -- Duplicate mark removal
    skip_code_blocks = true,         -- Skip markdown code blocks
})
```

---

## 🚀 Getting Started with This Documentation

### If You're...

**A User**: Read EXECUTIVE_SUMMARY.md and understand the fix  
**A Maintainer**: Read TECHNICAL_ANALYSIS.md for full understanding  
**A Contributor**: Read TECHNICAL_ANALYSIS.md + DEBUG_SESSION_SUMMARY.md  
**A Learner**: Start with EXECUTIVE_SUMMARY.md, then follow the progression  
**A Debugger**: Go straight to BUG_FIX_REPORT.md

---

## ✨ Summary

- **Issue**: Code block skipping failed due to incorrect Lua pattern
- **Root Cause**: Used PCRE-style `{3,}` instead of Lua-compatible pattern
- **Fix**: Changed to explicit three-backtick pattern `` %`%`%`%`* ``
- **Result**: All 18 tests pass, feature now works correctly
- **Impact**: No breaking changes, minimal code modification

---

## 📝 Documentation Generated

- December 23, 2025
- Total: 7 documentation files + this index
- Status: Complete and comprehensive ✅

---

**For questions or clarification, refer to the specific documentation file above.**
