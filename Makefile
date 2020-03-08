MODULES=$(wildcard lib/*.moon) lib/midi/launchctl.moon
MODREFS=$(MODULES:lib/%.moon=docs/reference/%.html)
DEPS=core/version.moon extra/docs.moon extra/layout.moon extra/dom.moon

.PHONY: docs reference internals release clean

docs: docs/index.html docs/guide.html reference internals

reference: $(MODREFS) docs/reference/index.html

release:
	rm -f core/version.moon
	extra/git-version.sh >core/version.moon

docs/%.html: docs/%.md $(DEPS)
	@echo "building page $<"
	moon extra/docs.moon $@ markdown $<

docs/reference/%.html: lib/%.moon $(DEPS) 
	@echo "building docs for $<"
	@mkdir -p `dirname $@`
	moon extra/docs.moon $@ module lib.$(subst /,.,$*) $(subst /,.,$*)

docs/reference/index.html: $(MODREFS) $(DEPS)
	moon extra/docs.moon $@ reference $(MODULES)

docs/ldoc.css: docs/style.css
	cp $< $@
	
docs/ldoc.ltp: $(DEPS)
	moon extra/docs.moon $@ ldoc

internals: core/config.ld docs/ldoc.ltp docs/ldoc.css
	ldoc core

clean:
	rm -rf docs/reference
	rm -rf docs/internals
	rm -f docs/index.html docs/guide.html docs/ldoc.*
