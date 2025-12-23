local test = '```'
print('String:', test)
print('String length:', #test)

-- Test the pattern from processor.lua
local pattern = "^%s*`{3,}"
local result = test:match(pattern)
print('Pattern: ' .. pattern)
print('Match result:', result)
print('Is nil?:', result == nil)

-- Try escaping backticks
local pattern2 = "^%s*`+$"
print('Pattern2: ' .. pattern2)
print('Match result2:', test:match(pattern2))

-- Try simpler
local pattern3 = "^```"
print('Pattern3: ' .. pattern3)
print('Match result3:', test:match(pattern3))

-- Try without anchor
local pattern4 = "%s*`{3,}"
print('Pattern4: ' .. pattern4)
print('Match result4:', test:match(pattern4))
