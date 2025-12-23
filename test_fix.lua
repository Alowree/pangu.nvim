#!/usr/bin/env lua
-- Standalone test to verify code block fence detection fix

-- Test the old broken pattern
local function old_is_fence(line)
    return line:match("^%s*`{3,}") ~= nil
end

-- Test the fixed pattern
local function new_is_fence(line)
    return line:match("^%s*`%`%`%`*") ~= nil
end

local test_cases = {
    "```",
    "   ```",
    "````",
    "  ````  ",
    "foo```",
    "```foo",
}

print("=== Code Block Fence Detection ===\n")
print("Testing fence detection patterns:\n")

for _, test_line in ipairs(test_cases) do
    local old_result = old_is_fence(test_line)
    local new_result = new_is_fence(test_line)
    local expected = test_line:match("^%s*`") ~= nil  -- Should match if line starts with optional spaces then backtick
    local status = (new_result == expected) and "✓" or "✗"
    
    print(string.format("%s Line: '%-20s' | Old: %-5s | New: %-5s | Expected: %-5s",
        status, test_line, tostring(old_result), tostring(new_result), tostring(expected)))
end

print("\n=== Functional Test ===\n")
-- Test the actual code block skipping logic
local function format_with_skip(text, skip_enabled)
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    local result = {}
    local in_code_block = false
    
    for i, line in ipairs(lines) do
        if line:match("^%s*`%`%`%`*") then  -- New pattern
            table.insert(result, line)
            if skip_enabled then
                in_code_block = not in_code_block
            end
        elseif in_code_block and skip_enabled then
            table.insert(result, line)
        else
            -- Simulate formatting: add space after 中文
            local formatted = line:gsub("中文(.)", "中文 %1")
            table.insert(result, formatted)
        end
    end
    
    return table.concat(result, "\n")
end

local input = "中文English\n```\n中文English\n```\n中文English"

print("Input:")
print(input)
print("\n--- With skip_enabled = true ---")
local result_skip = format_with_skip(input, true)
print(result_skip)
print("\nShould contain unformatted '中文English' inside code block: " .. 
    (result_skip:find("中文English") and "✓ YES" or "✗ NO"))
print("Should contain formatted '中文 English' outside code block: " .. 
    (result_skip:find("中文 English") and "✓ YES" or "✗ NO"))

print("\n--- With skip_enabled = false ---")
local result_no_skip = format_with_skip(input, false)
print(result_no_skip)
print("\nAll lines should be formatted (no '中文English'): " .. 
    (not result_no_skip:find("中文English") and "✓ YES" or "✗ NO"))
