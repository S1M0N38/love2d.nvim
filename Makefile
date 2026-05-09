.PHONY: test lint format check dev clean

test:
	# busted
	cd tests/game && nvim -u repro.lua --headless -c 'luafile ../e2e_game.lua' main.lua
	cd tests/bad-game && nvim -u repro.lua --headless -c 'luafile ../e2e_bad_game.lua' main.lua

lint:
	stylua --check lua/ spec/

format:
	stylua lua/ spec/

check: lint test

dev:
	cd tests/game && nvim -u repro.lua main.lua

clean:
	find . -type d -name '.repro' -exec rm -rf {} +
