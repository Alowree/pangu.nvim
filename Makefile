test:
	nvim --headless -u tests/minimal_init.lua \
	-c "lua require('plenary.busted')" \
	-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
