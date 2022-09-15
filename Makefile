# Disable built-in rules and variables
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# targets
.PHONY: all clean install

# source files
SRC_FILES := go-def.lua

# binary
BIN := go-def

# Lua
LUAC := luac5.3

# all
all: $(BIN)

# compilation
$(BIN): $(SRC_FILES)
	$(LUAC) -s -o $@ $^
	sed -i '1s|^|\#!/usr/bin/env lua5.3\n|' $@ && chmod +x $@

# clean up
clean:
	rm -f $(BIN)

# installation
XDG_DATA_HOME ?= $(HOME)/.local/share
INSTALL_DIR ?= $(XDG_DATA_HOME)/kate/tools

install: $(BIN)
	mkdir -p $(INSTALL_DIR)
	cp $(BIN) $(INSTALL_DIR)
