# This Makefile is _not_ required! It is only intended for advanced users.
#
# Usage:
#
# make create-switch - Create a switch with dkml-base-compiler
# make devtools - Install OCaml LSP

OCAMLVERSION=4.12.1
DKMLVERSION=1.0.0
PACKAGENAME=your_example

all: install
.PHONY: all

## -----------------------------------------------------------
## BEGIN Opam and Dune basics

create-switch: _opam/.opam-switch/switch-config
devtools: _opam/bin/ocamllsp
.PHONY: create-switch devtools

_opam/.opam-switch/switch-config:
	opam switch create . dkml-base-compiler.$(OCAMLVERSION)~v$(DKMLVERSION) \
	  --yes \
	  --deps-only \
	  --repo default=https://opam.ocaml.org,dune-universe=git+https://github.com/dune-universe/opam-overlays.git

_opam/bin/dune: _opam/.opam-switch/switch-config
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam install dune --yes

$(PACKAGENAME).opam: dune-project _opam/bin/dune $(PACKAGENAME).opam.template
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  eval $$(opam env) && \
	  dune build $@ && \
	  touch $@

_opam/bin/ocamllsp: _opam/.opam-switch/switch-config
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam install ocaml-lsp-server ocamlformat-rpc --yes

## END Opam and Dune basics
## -----------------------------------------------------------

## -----------------------------------------------------------
## BEGIN Opam Monorepo

monorepo-available: _opam/bin/opam-monorepo
monorepo-lock: $(PACKAGENAME).opam.locked
monorepo-pull: duniverse/README.md
.PHONY: monorepo-available monorepo-lock monorepo-pull

_opam/bin/opam-monorepo: _opam/.opam-switch/switch-config
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam install opam-monorepo --yes

$(PACKAGENAME).opam.locked: $(PACKAGENAME).opam _opam/bin/opam-monorepo
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam monorepo lock $(PACKAGENAME) --ocaml-version=$(OCAMLVERSION) --require-cross-compile -vv

duniverse/README.md: $(PACKAGENAME).opam.locked
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam monorepo pull --yes && \
	  touch "$@"

install: _opam/bin/opam-monorepo $(PACKAGENAME).opam.locked
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam install conf-dkml-cross-toolchain . --locked --yes
.PHONY: install

build: _opam/bin/opam-monorepo $(PACKAGENAME).opam.locked
	OPAMSWITCH="$$PWD" && if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  eval $$(opam env) && \
	  dune build
.PHONY: build

## END Opam Monorepo
## -----------------------------------------------------------
