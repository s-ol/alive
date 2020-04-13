MODULES=$(wildcard lib/*.moon) lib/midi/launchctl.moon
MODREFS=$(MODULES:lib/%.moon=docs/reference/%.html)
CORE=$(wildcard alv/*.moon alv/**/*.moon) $(wildcard alv/*.md)
DEPS=alv/version.moon extra/docs.moon extra/layout.moon extra/dom.moon

.PHONY: docs reference internals release clean

docs: docs/index.html docs/guide.html reference internals
reference: $(MODREFS) docs/reference/index.html
internals: docs/internals/index.html

release:
	rm -f alv/version.moon
	extra/git-version.sh >alv/version.moon

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

docs/internals/index.html: alv/config.ld docs/ldoc.ltp docs/ldoc.css $(CORE)
	ldoc alv

clean:
	rm -rf docs/reference
	rm -rf docs/internals
	rm -f docs/index.html docs/guide.html docs/ldoc.*
