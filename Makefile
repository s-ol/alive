MODULES:=$(sort $(wildcard alv-lib/*.moon))
MODULES:=$(filter-out $(wildcard alv-lib/_*.moon), $(MODULES))
MODULES:=$(MODULES:alv-lib/%.moon=docs/reference/module/%.html)
REFERENCE=docs/reference/index.md $(sort $(wildcard docs/reference/[01]*.md)) docs/reference/builtins.html $(MODULES)
REFTOC=$(REFERENCE:%.md=%.html)

GUIDE=docs/guide/index.md $(sort $(wildcard docs/guide/[01]*.md))
GUIDETOC=$(GUIDE:%.md=%.html)

CORE=$(wildcard alv/*.moon alv/**/*.moon) $(wildcard alv/*.md)
DEPS=alv/version.moon $(wildcard docs/gen/*.moon)
GEN=docs/gen/

.PHONY: docs test release clean guide reference internals

docs: docs/index.html guide reference internals

test:
	busted

# docs parts
guide: $(GUIDETOC)
reference: $(REFTOC)
internals: docs/internals/index.html

docs/guide/%.html: docs/guide/%.md $(GUIDE) $(DEPS) $(GEN)md
	@echo "building page $<"
	docs/gen/md $@ $< $(GUIDETOC)

docs/reference/module/%.html: alv-lib/%.moon $(DEPS) $(GEN)module
	@echo "building docs for $<"
	@mkdir -p `dirname $@`
	docs/gen/module $@ alv-lib.$(subst /,.,$*) $(subst /,.,$*) $(REFTOC)

docs/reference/builtins.html: alv/builtins.moon $(DEPS) $(GEN)module
	@echo "building docs for $<"
	docs/gen/module $@ alv.builtins "builtins" $(REFTOC)

docs/reference/index.html: docs/reference/index.md alv/builtins.moon $(MODULES) $(DEPS) $(GEN)index
	@echo "building reference index"
	docs/gen/index $@ $< $(REFTOC)
	
docs/reference/%.html: docs/reference/%.md $(REFERENCE) $(DEPS) $(GEN)md
	@echo "building page $<"
	docs/gen/md $@ $< $(REFTOC)

docs/%.html: docs/%.md $(DEPS) $(GEN)md
	@echo "building page $<"
	docs/gen/md $@ $<

docs/ldoc.ltp: $(DEPS)
	docs/gen/ldoc $@

docs/internals/index.html: alv/config.ld docs/ldoc.ltp $(CORE)
	ldoc alv

clean:
	rm -rf docs/reference/*.html docs/reference/modules
	rm -rf docs/internals/*/ docs/internals/*.css docs/internals/*.html
	rm -f docs/index.html $(GUIDETOC) docs/ldoc.*
