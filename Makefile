include Make.terraform

DOCS_FILES = MODULE.md

$(DOCS_FILES): .terraform-docs.yml
	terraform-docs . > $@

clean:
	rm -f $(DOCS_FILES)

docs: $(DOCS_FILES)

.PHONY: docs clean
