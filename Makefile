.PHONY: test test-one lint format check dev

test:
	busted

test-one:
	busted -o utf_terminal $(FILE)

lint:
	stylua --check lua/ spec/

format:
	stylua lua/ spec/

check: lint test

dev:
	cd tests/game && nvim -u repro.lua main.lua
