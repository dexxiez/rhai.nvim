# Dev tasks for rhai.nvim. Start with `make deps`, then `make test`.

NVIM   ?= nvim
STYLUA ?= stylua
LUALS  ?= lua-language-server

# Pinned revisions live in the Lua code, so there is one source of truth.
LSP_REV := $(shell sed -n 's/^M.revision = "\(.*\)"/\1/p' lua/rhai/install.lua)
TS_REV  := $(shell sed -n 's/^M.revision = "\(.*\)"/\1/p' lua/rhai/treesitter.lua)

RHAI_LSP_BIN    ?= $(if $(wildcard .deps/bin/rhai),$(abspath .deps/bin/rhai),rhai)
RHAI_PARSER_DIR ?= $(abspath .deps/ts)

.PHONY: all test lint format typecheck deps deps-lsp deps-parser clean

all: lint typecheck test

test:
	RHAI_LSP_BIN="$(RHAI_LSP_BIN)" RHAI_PARSER_DIR="$(RHAI_PARSER_DIR)" $(NVIM) -l tests/run.lua

lint:
	$(STYLUA) --check .

format:
	$(STYLUA) .

# Needs VIMRUNTIME so lua-language-server can see Neovim's types.
typecheck:
	VIMRUNTIME="$${VIMRUNTIME:-$$($(NVIM) --clean --headless --cmd 'lua io.write(vim.env.VIMRUNTIME)' --cmd q)}" \
		$(LUALS) --check . --checklevel=Warning --logpath .deps/luals

deps: deps-lsp deps-parser

# Builds the `rhai` language server into .deps/bin (takes a few minutes).
deps-lsp:
	cargo install --root .deps --git https://github.com/rhaiscript/lsp --rev $(LSP_REV) --locked rhai-cli

# Compiles the tree-sitter parser into .deps/ts/parser/rhai.so.
deps-parser:
	rm -rf .deps/tree-sitter-rhai
	git init -q .deps/tree-sitter-rhai
	git -C .deps/tree-sitter-rhai fetch -q --depth 1 https://github.com/elkowar/tree-sitter-rhai $(TS_REV)
	git -C .deps/tree-sitter-rhai checkout -q FETCH_HEAD
	mkdir -p .deps/ts/parser
	$(CC) -O2 -shared -fPIC -I .deps/tree-sitter-rhai/src \
		.deps/tree-sitter-rhai/src/parser.c -o .deps/ts/parser/rhai.so

clean:
	rm -rf .deps
