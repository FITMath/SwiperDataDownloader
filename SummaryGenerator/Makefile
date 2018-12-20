SHELL=/bin/bash
LASTFRIDAY=$(shell date --date='last Friday' +%m-%d-%Y)
OUTPUTDIR?=.
DATADIR?=.
DATAFILE?=all-$(LASTFRIDAY).csv
JULIA?=$(shell which julia)

instantiate: Project.toml
	$(JULIA) --project=. -e 'using Pkg; Pkg.instantiate()'

$(OUTPUTDIR)/%/fileDescriptions.jldat: plotDataGenerator.jl $(DATADIR)/all-%.csv
	$(JULIA) --project=. $^ $(dir $@)

$(OUTPUTDIR)/%/_index.md: postTemplateGenerator.jl $(OUTPUTDIR)/%/fileDescriptions.jldat
	$(JULIA) --project=. $^
