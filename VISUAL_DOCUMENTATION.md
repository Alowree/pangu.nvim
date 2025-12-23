# Pangu.nvim - Visual Documentation

## Formatting Pipeline Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          INPUT TEXT                              │
│                  "中文English中文, test"                          │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
        ┌─────────────────────┐
        │   TOKENIZATION      │
        │  (tokenizer.lua)    │
        └────────┬────────────┘
                 │
        ┌────────▼──────────────────────────────┐
        │ Tokens with Types:                     │
        │  [中] CHINESE                          │
        │  [文] CHINESE                          │
        │  [E] ENGLISH                           │
        │  [n] ENGLISH                           │
        │  ...                                   │
        └────────┬──────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────────┐
│            FORMATTING RULES (processor.lua)                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [if enabled] add_space_between_cjk_and_english()               │
│      中文English → 中文 English                                   │
│                                                                  │
│  [if enabled] add_space_between_cjk_and_digit()                 │
│      中文123 → 中文 123                                           │
│                                                                  │
│  [if enabled] convert_punctuation()                             │
│      中文, → 中文，                                               │
│                                                                  │
│  [if enabled] convert_parentheses()                             │
│      中文(test) → 中文（test）                                    │
│                                                                  │
│  [if enabled] convert_quotes()                                  │
│      中文"test" → 中文"test"                                      │
│                                                                  │
│  [if enabled] normalize_repeated_marks()                        │
│      中文。。。 → 中文。                                           │
│                                                                  │
└────────────────┬─────────────────────────────────────────────────┘
                 │
                 ▼
        ┌─────────────────────┐
        │   OUTPUT TEXT       │
        │ "中文 English 中文，│
        │     test"          │
        └─────────────────────┘
```

## Code Block State Machine

````
                    START
                      │
            [in_code_block = false]
                      │
              ┌───────▼───────┐
              │  Read Line    │
              └───────┬───────┘
                      │
            ┌─────────┴─────────┐
            │                   │
            ▼                   ▼
      Is Fence?          Not a Fence?
         (```)                 │
         │                     │
         │              ┌──────┴─────┐
         │              │            │
         │          in_code_  skip_code_
         │          block &&  blocks
         │            enabled  enabled?
         │              │         │
         │              ▼         ▼
         │          SKIP      FORMAT
         │         Output     Apply all
         │          as-is     rules
         │              │         │
         │       ┌──────┴─────┐   │
         │       │   Output   │   │
         │       │  line      │   │
         │       └──────┬─────┘   │
         │              │         │
         ▼              │         │
      TOGGLE       ┌────┴────┐    │
    in_code_block  │ Output  │◄───┘
         │         │ result  │
         │         └────┬────┘
         │              │
         └──────┬───────┘
                │
         More lines? ──YES──► Loop back to "Read Line"
                │
               NO
                │
                ▼
             OUTPUT BUFFER
````

## Character Classification

```
┌─────────────────────────────────────────┐
│         CHARACTER CLASSIFICATION         │
├─────────────────────────────────────────┤
│                                         │
│  CHINESE                               │
│  └─ Unicode: U+4E00-U+9FFF             │
│     and other CJK ranges               │
│                                         │
│  ENGLISH                               │
│  └─ [a-zA-Z]                           │
│                                         │
│  DIGIT                                 │
│  └─ [0-9]                              │
│                                         │
│  WHITESPACE                            │
│  └─ [ \t\n\r]                          │
│                                         │
│  PUNCTUATION                           │
│  └─ . , ; : ! ?                        │
│                                         │
│  MARKDOWN_CODE                         │
│  └─ `  (backtick)                      │
│                                         │
│  MARKDOWN_BOLD                         │
│  └─ * or _                             │
│                                         │
│  MARKDOWN_LINK                         │
│  └─ [ ] ( )                            │
│                                         │
│  OTHER                                 │
│  └─ Everything else                    │
│                                         │
└─────────────────────────────────────────┘
```

## Punctuation Conversion Map

```
English → Chinese (when preceded by CJK)

  ,  ───────────► ，
  .  ───────────► 。
  ;  ───────────► ；
  :  ───────────► ：
  ?  ───────────► ？
  !  ───────────► ！
  \  ───────────► 、

Parenthesis Conversion:
  (  ◄────────► （
  )  ◄────────► ）

Quote Conversion:
  "  ───────────► ""
  '  ───────────► ''
```

## File Organization

```
pangu.nvim/
│
├── lua/pangu/
│   │
│   ├── init.lua
│   │   ├─ Main API
│   │   ├─ Exports: setup(), format(), config
│   │   └─ User-facing interface
│   │
│   ├── config.lua
│   │   ├─ Configuration defaults
│   │   ├─ Functions: setup(), get(), set()
│   │   └─ Feature toggle flags
│   │
│   ├── processor.lua (421 lines)
│   │   ├─ format(text)                ← Main function
│   │   ├─ format_buffer(bufnr)        ← With code block handling
│   │   ├─ format_range(bufnr, s, e)   ← Range formatting
│   │   ├─ add_space_between_cjk_and_english()
│   │   ├─ add_space_between_cjk_and_digit()
│   │   ├─ add_space_around_markdown()
│   │   ├─ convert_punctuation()
│   │   ├─ convert_parentheses()
│   │   ├─ convert_quotes()
│   │   ├─ normalize_repeated_marks()
│   │   └─ is_code_block_fence()      ← FIXED!
│   │       Pattern: ^%s*`%`%`%`*
│   │
│   ├── tokenizer.lua (105 lines)
│   │   ├─ split_utf8(text)
│   │   ├─ classify_token(token)
│   │   ├─ tokenize(text)
│   │   └─ TokenType enum
│   │
│   └── utils.lua (107 lines)
│       ├─ is_chinese(char)
│       ├─ is_english_or_digit(char)
│       ├─ is_whitespace(char)
│       ├─ is_chinese_punctuation(char)
│       ├─ punct_map
│       ├─ paren_map
│       ├─ quote_map
│       └─ dedup_chars
│
└── tests/
    └── test_processor.lua
        ├─ 16 formatting tests
        ├─ 2 code block tests
        └─ All 18 tests passing ✅
```

## The Lua Pattern Bug Explained

`````
Regex Quantifiers (PCRE/Perl)
┌────────────────────────────────────┐
│  Pattern  │  Meaning               │
├───────────┼────────────────────────┤
│  x{3}     │  Exactly 3 x's         │
│  x{3,}    │  3 or more x's         │
│  x{3,5}   │  Between 3 and 5 x's   │
└────────────────────────────────────┘

Lua Patterns (Neovim/Lua)
┌────────────────────────────────────┐
│  Pattern  │  Meaning               │
├───────────┼────────────────────────┤
│  x*       │  0 or more x's         │
│  x+       │  1 or more x's         │
│  x?       │  0 or 1 x              │
│  x-       │  0+ x's (non-greedy)   │
└────────────────────────────────────┘

❌ BROKEN: line:match("^%s*`{3,}")
   • {3,} is treated as LITERAL characters
   • Looks for: space, backtick, {, 3, ,, }

✅ FIXED: line:match("^%s*`%`%`%`*")
   • Matches: space, backtick, backtick, backtick, (more backticks)
   • Works correctly for ``` and ````
`````

## Configuration Hierarchy

```
        DEFAULT CONFIG
        (config.lua)
              │
              │ M.defaults = {
              │   enable_spacing = true,
              │   skip_code_blocks = true,
              │   ...
              │ }
              │
              ▼
        USER SETUP()

   require("pangu").setup({
       enable_spacing = false,  ← Overrides default
       enable_dedup_marks = true
   })
              │
              ▼
      MERGED CONFIG
      (in memory)
              │
      ┌───────┴────────┬─────────────┬──────────┐
      │                │             │          │
  enable_          enable_          skip_    add_space_
 spacing      punct_convert     code_blocks  around_
                            markdown
```

## UTF-8 Character Handling

```
String: "中文English"

Byte representation:
  中 = E4 B8 AD (3 bytes)
  文 = E6 96 87 (3 bytes)
  E = 45 (1 byte)
  n = 6E (1 byte)
  g = 67 (1 byte)
  l = 6C (1 byte)
  i = 69 (1 byte)
  s = 73 (1 byte)
  h = 68 (1 byte)

split_utf8() correctly handles multi-byte chars:
  ["中", "文", "E", "n", "g", "l", "i", "s", "h"]

Each element is then classified:
  ["中"→CHINESE, "文"→CHINESE, "E"→ENGLISH, "n"→ENGLISH, ...]
```

---

Generated: December 23, 2025
