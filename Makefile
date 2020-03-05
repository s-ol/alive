MODULES=$(wildcard lib/*.moon) lib/midi/launchctl.moon
MODREFS=$(MODULES:lib/%.moon=docs/reference/%.html)
DEPS=core/version.moon extra/docs.moon extra/layout.moon extra/dom.moon

.PHONY: docs release clean

docs: docs/index.html docs/guide.html $(MODREFS) docs/reference/index.html

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

clean:
	rm -rf docs/reference/*
	rm docs/index.html docs/guide.html
