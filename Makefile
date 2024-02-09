.PHONY: test lint docs init

TESTS_DIR := tests/
PLUGIN_DIR := lua/

DOC_GEN_SCRIPT := ./scripts/docs.lua
MINIMAL_INIT := ./scripts/minimal_init.vim

test:
	nvim --headless --noplugin -u ${MINIMAL_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${MINIMAL_INIT}' }"

lint:
	luacheck ${PLUGIN_DIR}

docs:
	nvim --headless --noplugin -u ${MINIMAL_INIT} \
		-c "luafile ${DOC_GEN_SCRIPT}" -c 'qa'

init:
	@nvim --headless --noplugin \
	  -c "vimgrep /my_awesome_plugin/gj **/*.lua **/*.vim Makefile" \
	  -c "cfdo %s/my_awesome_plugin/$(name)/ge | update" \
	  -c "qa"
	@find . -depth -type d -name '*my_awesome_plugin*' | \
	  while read dir; do mv "$$dir" "$${dir//my_awesome_plugin/$(name)}"; done
	@find . -type f -name '*my_awesome_plugin*' | \
	  while read file; do mv "$$file" "$${file//my_awesome_plugin/$(name)}"; done
