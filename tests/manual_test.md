# pangu.nvim Manual Test Playground

## Instructions for Users

<!-- pangu-ignore-start -->

This file contains various edge cases and scenarios supported by `pangu.nvim`.

1. Open this file in Neovim.
2. Ensure `pangu.nvim` is installed and loaded
3. Remove the pangu-ignore directives for selected area to test
4. Run `:Pangu` and observe the changes
5. If `enable_on_save` is `true,` simply save the file (`:w`) to see the magic

<!-- pangu-ignore-start -->

## 1. Basic Spacing (CJK & English/Digits)

<!-- pangu-ignore-start -->

- Before: 中文English中文和123数字。
- Expected: 中文 English 中文 和 123 数字。

<!-- pangu-ignore-end -->

## 2. Markdown Elements

Before: 中文 English 中文和 123 数字。 Before: 中文 English 中文和 123 数字。
Before: 中文 English 中文和 123 数字。

<!-- pangu-ignore-start -->

- Code: 运行`npm install`命令。
- Bold: 这是**重要**的内容。
- Italic: 这是*重要*的内容。
- Bold Italic: 这是***重要***的内容。
- Link: 点击[这里](https://github.com)查看。
- Expected: Spaces should appear around the Markdown elements (e.g., 点击 [这里](url) 查看).

<!-- pangu-ignore-end -->

## 3. Punctuation & Parentheses

<!-- pangu-ignore-start -->

- Before: 你好,世界.这是一个(备注)。
- Expected: 你好，世界。这是一个（备注）。
- Before: This is an English context （note）.
- Expected: No change to parentheses in English context.

<!-- pangu-ignore-end -->

## 4. Quote Normalization

<!-- pangu-ignore-start -->

- Before: 他说"你好"，我也说'你好'。
- Expected: 他说“你好”，我也说‘你好’。

<!-- pangu-ignore-end -->

## 5. Deduplication

<!-- pangu-ignore-start -->

- Before: 到底为什么？？？完成。。。
- Expected: 到底为什么？完成。

<!-- pangu-ignore-end -->

## 6. Code Block Preservation (Should NOT change)

```python
# The content below should remain unformatted
def hello():
    print("中文English测试")
```

Even three backticks inside a four-backtick block are safe.

## 7. Manual Ignore Blocks (Should NOT change)

<!-- pangu-ignore-start -->

- Before: 中文English更多123和(括号)里的"引用"。。。为什么？？？
- Expected: 中文English更多123和(括号)里的"引用"。。。为什么？？？

<!-- pangu-ignore-end -->
