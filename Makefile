.PHONY: test test-one lint format check dev clean

test:
	nvim -l tests/minit.lua --minitest

test-one:
	nvim -l tests/minit.lua --minitest tests/$(MODULE)_spec.lua

lint:
	@export TMPFILE="/tmp/love2d_vimruntime" && \
		nvim --headless -c 'lua io.open(os.getenv("TMPFILE"),"w"):write(vim.env.VIMRUNTIME or ""):close()' -c 'q' 2>/dev/null && \
		VIMRUNTIME="$$(cat "$$TMPFILE")" && rm -f "$$TMPFILE" && \
		test -n "$$VIMRUNTIME" && \
		export VIMRUNTIME && \
		lua-language-server --check_format=pretty --check lua/ --configpath="$$(pwd)/.luarc.json" --checklevel=Warning

format:
	stylua lua/ tests/

check: lint test

dev:
	cd tests/demo-game && nvim -u repro.lua main.lua

clean:
	find . -type d -name '.repro' -exec rm -rf {} +
	find . -type d -name '.tests' -exec rm -rf {} +
