MODULES=$(wildcard alv-lib/*.moon) alv-lib/midi/launchctl.moon
MODREFS=$(MODULES:alv-lib/%.moon=docs/reference/%.html)
CORE=$(wildcard alv/*.moon alv/**/*.moon) $(wildcard alv/*.md)
DEPS=alv/version.moon $(wildcard docs/gen/*.moon)

.PHONY: docs test release clean reference internals

GUIDE  = getting-started-guide installation hello-world syntax
GUIDE += working-with-the-copilot basic-types importing-operators defining-symbols
GUIDE += scopes functions evaltime-and-runtime making-sound
GUIDE := $(addprefix docs/guide/,$(addsuffix .md,$(GUIDE)))
docs: docs/index.html $(GUIDE:%.md=%.html) reference internals

test:
	busted

# docs parts
reference: $(MODREFS) docs/reference/index.html
internals: docs/internals/index.html

docs/guide/%.html: docs/guide/%.md $(DEPS) $(GUIDE)
	@echo "building page $<"
	docs/gen/md $@ $< $(GUIDE:%.md=%.html)

docs/%.html: docs/%.md $(DEPS)
	@echo "building page $<"
	docs/gen/md $@ $<

docs/reference/%.html: alv-lib/%.moon $(DEPS) 
	@echo "building docs for $<"
	@mkdir -p `dirname $@`
	docs/gen/module $@ alv-lib.$(subst /,.,$*) $(subst /,.,$*)

docs/reference/index.html: alv/builtins.moon $(MODREFS) $(DEPS)
	docs/gen/index $@ $(MODULES)

docs/ldoc.ltp: $(DEPS)
	docs/gen/ldoc $@

docs/internals/index.html: alv/config.ld docs/ldoc.ltp $(CORE)
	ldoc alv

clean:
	rm -rf docs/reference
	rm -rf docs/internals/*/ docs/internals/*.css docs/internals/*.html
	rm -f docs/index.html $(GUIDE:%.md=%.html) docs/ldoc.*
