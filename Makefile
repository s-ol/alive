MODULES=$(wildcard alv-lib/*.moon) alv-lib/midi/launchctl.moon
MODREFS=$(MODULES:alv-lib/%.moon=docs/reference/%.html)
CORE=$(wildcard alv/*.moon alv/**/*.moon) $(wildcard alv/*.md)
DEPS=alv/version.moon $(wildcard docs/gen/*.moon)

.PHONY: docs test release clean reference internals

docs: docs/index.html docs/guide.html reference internals
	
test:
	busted

# docs parts
reference: $(MODREFS) docs/reference/index.html
internals: docs/internals/index.html

docs/%.html: docs/%.md $(DEPS)
	@echo "building page $<"
	docs/gen/md $@ $<

docs/reference/%.html: alv-lib/%.moon $(DEPS) 
	@echo "building docs for $<"
	@mkdir -p `dirname $@`
	docs/gen/module $@ alv-lib.$(subst /,.,$*) $(subst /,.,$*)

docs/reference/index.html: $(MODREFS) $(DEPS)
	docs/gen/index $@ $(MODULES)

docs/ldoc.css: docs/style.css
	cp $< $@
	
docs/ldoc.ltp: $(DEPS)
	docs/gen/ldoc $@

docs/internals/index.html: alv/config.ld docs/ldoc.ltp docs/ldoc.css $(CORE)
	ldoc alv

clean:
	rm -rf docs/reference
	rm -rf docs/internals
	rm -f docs/index.html docs/guide.html docs/ldoc.*
