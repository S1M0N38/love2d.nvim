.PHONY: test lint init

TESTS_DIR := tests/
PLUGIN_DIR := lua/

MINIMAL_INIT := ./tests/minimal_init.lua

test:
	nvim --headless --noplugin -u ${MINIMAL_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${MINIMAL_INIT}' }"

lint:
	luacheck ${PLUGIN_DIR}
