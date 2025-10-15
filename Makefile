MARPC=npx @marp-team/marp-cli@latest --allow-local-files
MD_FILES=$(filter-out README.md, $(wildcard *.md))
PDFS=$(MD_FILES:.md=.pdf)
HTMLS=$(MD_FILES:.md=.html)

all: $(PDFS) $(HTMLS)

%.pdf: %.md
	$(MARPC) --pdf $< -o $@

%.html: %.md
	$(MARPC) $< -o $@

clean:
	rm -f $(PDFS) $(HTMLS)