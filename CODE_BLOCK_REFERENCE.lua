#!/usr/bin/env lua
-- Quick reference: Lua pattern syntax for code block detection

print("=== PANGU.NVIM CODE BLOCK DETECTION - QUICK REFERENCE ===\n")

print("PROBLEM:")
print("--------")
print("Original pattern: line:match(\"^%s*`{3,}\") ~= nil")
print("Issue: In Lua, {3,} is NOT a 'repeat 3+ times' quantifier")
print("       It's literal characters to match!")
print()

print("SOLUTION:")
print("---------")
print("Fixed pattern: line:match(\"^%s*`%`%`%`*\") ~= nil")
print()
print("Pattern breakdown:")
print("  ^      = Start of line")
print("  %s*    = Zero or more whitespace")
print("  %`     = One literal backtick (escaped)")
print("  %`     = One literal backtick (escaped)")
print("  %`     = One literal backtick (escaped)")
print("  %`*    = Zero or more additional backticks")
print()

print("EXAMPLES:")
print("---------")
local function matches_fence(line)
    return line:match("^%s*`%`%`%`*") ~= nil
end

local test_lines = {
    {"```", true},
    {"`````", true},
    {"   ```", true},
    {"  ````  ", true},
    {"code```", false},
    {"```code", true},  -- Note: ``` at start still matches even with trailing text
    {"``", false},
    {"", false},
    {"   ", false},
}

for _, test in ipairs(test_lines) do
    local line, expected = test[1], test[2]
    local result = matches_fence(line)
    local status = (result == expected) and "✓" or "✗"
    print(string.format("%s  '%-20s' → %s", status, line, tostring(result)))
end

print()
print("CONFIGURATION:")
print("--------------")
print("- File: lua/pangu/config.lua")
print("- Setting: skip_code_blocks = true (default)")
print("- Effect: Lines inside ``` ``` blocks are NOT formatted")
print()
print("Usage:")
print("  require('pangu').setup({ skip_code_blocks = false })  -- Disable skipping")
print("  require('pangu').setup({ skip_code_blocks = true })   -- Enable skipping (default)")
