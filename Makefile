MODULES=$(wildcard lib/*.moon) lib/midi/launchctl.moon
MODREFS=$(MODULES:lib/%.moon=docs/reference/%.html)

.PHONY: docs clean

docs: docs/index.html docs/guide.html $(MODREFS) docs/reference/index.html

docs/%.html: docs/%.md extra/docs.moon extra/layout.moon
	@echo "building page $<"
	moon extra/docs.moon $@ markdown $<

docs/reference/%.html: lib/%.moon extra/docs.moon extra/layout.moon
	@echo "building docs for $<"
	@mkdir -p `dirname $@`
	moon extra/docs.moon $@ module lib.$(*:/=.) $*

docs/reference/index.html: $(MODREFS) extra/docs.moon extra/layout.moon
	moon extra/docs.moon $@ reference $(MODULES)

clean:
	rm -rf docs/reference/*
	rm docs/index.html docs/guide.html
