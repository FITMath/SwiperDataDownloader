SHELL=/bin/bash
LASTFRIDAY=$(shell date --date='last Friday' +%m-%d-%Y)
OUTPUTDIR?=.
DATADIR?=.
JULIA?=$(shell which julia)

usage:
	@echo "Usage: make -f path/to/Makefile [OUTPUTFILE] VAR=VALUE..."
	@echo ""
	@echo "Recognized variables (VAR):"
	@echo "   OUTPUTDIR: Base output directory."
	@echo "   DATADIR: Base directory for input files."
	@echo "   JULIA: Path to Julia (v0.7+) executable."
	@echo ""
	@echo "Recognized targets: "
	@echo "   instantiate: ensure the necessary Julia packages are downloaded."
	@echo "   OUTPUTDIR/.../fileDescriptions.jldat: create graphics based on"
	@echo "       file DATADIR/all-....csv."
	@echo "   OUTPUTDIR/.../_index.md: create index/listing file corresponding to"
	@echo "       OUTPUTDIR/.../fileDescriptions.jldat."

Manifest.toml: Project.toml
	$(JULIA) --project=. -e 'using Pkg; Pkg.instantiate()'

$(OUTPUTDIR)/%/fileDescriptions.jldat: plotDataGenerator.jl $(DATADIR)/all-%.csv Manifest.toml
	$(JULIA) --project=. $< $(dir $@) $(DATADIR)/all-$*.csv

$(OUTPUTDIR)/%/_index.md: postTemplateGenerator.jl $(OUTPUTDIR)/%/fileDescriptions.jldat
	$(JULIA) --project=. $^ > $@
