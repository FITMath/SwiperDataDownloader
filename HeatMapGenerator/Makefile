SHELL=/bin/bash
JULIA?=$(shell which julia)
DATAFILE?=

usage:
	@echo "Usage: make -f path/to/Makefile [target] [VAR=VALUE...]"
	@echo ""
	@echo "Recognized variables (VAR):"
	@echo "   JULIA: Path to Julia (v0.7+) executable."
	@echo "   DATAFILE: Path to data file."
	@echo "   STEMOUT: Path and filename stem for output plots."
	@echo "   OPTS: Additional options to pass to the heat map generator."
	@echo ""
	@echo "Recognized targets: "
	@echo "   Manifest.toml: ensure the necessary Julia packages are downloaded."
	@echo "   heatMap: Generate the heat map from data in DATAFILE $(DATAFILE)."

Manifest.toml: Project.toml
	PYTHON="$(shell which python)" $(JULIA) --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build("PyCall")'

# Make sure that ${DATAFILE} exists and the script exits correctly,
# otherwise, give the usage information.
heatMap: makeHeatMap.jl Manifest.toml
	test -f "${DATAFILE}" && \
	${JULIA} --project=. $< -- "${DATAFILE}" "${STEMOUT}" \
	|| $(MAKE) usage
