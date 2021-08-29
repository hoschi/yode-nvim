test:
	nvim --headless -c "PlenaryBustedDirectory lua/yode-nvim/tests/ {minimal_init = 'lua/yode-nvim/tests/minimal.vim'}"

format:
	stylua lua/yode-nvim/*.lua lua/yode-nvim/redux/*.lua lua/yode-nvim/tests/*/*.lua

