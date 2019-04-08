# ------------------------------------------------------------------------------
# Copyright (c) 2019 Angel Terrones <angelterrones@gmail.com>
# ------------------------------------------------------------------------------
include tests/verilator/pprint.mk
SHELL=bash

# ------------------------------------------------------------------------------
PROJECTNAME = core
# ------------------------------------------------------------------------------
SUBMAKE			= $(MAKE) --no-print-directory
ROOT			= $(shell pwd)
BFOLDER			= build
VCOREMK			= tests/verilator

RVTESTSF		= tests/riscv-tests
RVBENCHMARKSF	= tests/benchmarks
RVXTRASF		= tests/extra-tests

TBEXE			= $(BFOLDER)/$(PROJECTNAME).exe --timeout 50000000 --file
UCGEN			= rtl/ucontrolgen.py
PYTHON			= python3
UCONTROL		= $(BFOLDER)/ucontrol.mem

# Compliance tests
RVCOMPLIANCE = $(ROOT)/tests/riscv-compliance

# export variables
export RISCV_PREFIX ?= riscv-none-embed-
export ROOT
export UFILE = $(UCONTROL)

# ------------------------------------------------------------------------------
# targets
# ------------------------------------------------------------------------------
help:
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "Please, choose one target:"
	@echo -e "- compile-tests:  Compile RISC-V assembler tests, benchmarks and extra tests."
	@echo -e "- build-model:    Build C++ core model."
	@echo -e "- run-tests:      Execute assembler tests, benchmarks and extra tests."
	@echo -e "--------------------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# Install repo
# ------------------------------------------------------------------------------
install-compliance:
	@./scripts/install_compliance

# ------------------------------------------------------------------------------
# verilate and build
# ------------------------------------------------------------------------------
build-core: $(UCONTROL)
	+@$(SUBMAKE) -C $(VCOREMK)

# ------------------------------------------------------------------------------
# TODO Delete
# compile tests
# ------------------------------------------------------------------------------
compile-tests:
	+@$(SUBMAKE) -C $(RVTESTSF)
	+@$(SUBMAKE) -C $(RVBENCHMARKSF)
	+@$(SUBMAKE) -C $(RVXTRASF)

# ------------------------------------------------------------------------------
# verilate and build
$(UCONTROL): $(UCGEN)
	@mkdir -p $(BFOLDER)
	@$(PYTHON) $(UCGEN) $(UCONTROL)

# ------------------------------------------------------------------------------
# verilator tests
run-tests: build-core compile-tests
	$(eval RVTESTS:=$(shell find $(RVTESTSF) -name "rv32ui*.elf" -o -name "rv32um*.elf" -o -name "rv32mi*.elf" ! -name "*breakpoint*.elf"))
	$(eval RVBENCHMARKS:=$(shell find $(RVBENCHMARKSF) -name "*.riscv"))
	$(eval RVXTRAS:=$(shell find $(RVXTRASF) -name "*.riscv"))

	@for file in $(RVTESTS) $(RVBENCHMARKS) $(RVXTRAS); do							\
		$(TBEXE) $$file --mem-delay $$delay > /dev/null;							\
		if [ $$? -eq 0 ]; then														\
			printf "%-50b %b\n" $$file "$(OK_COLOR)$(OK_STRING)$(NO_COLOR)";		\
		else																		\
			printf "%-50s %b" $$file "$(ERROR_COLOR)$(ERROR_STRING)$(NO_COLOR)\n";	\
		fi;																			\
	done
# ------------------------------------------------------------------------------
# clean
# ------------------------------------------------------------------------------
clean:
	@$(SUBMAKE) -C $(VCOREMK) clean

distclean: clean
	@rm -rf $(BFOLDER)
	@$(SUBMAKE) -C $(RVTESTSF) clean
	@$(SUBMAKE) -C $(RVBENCHMARKSF) clean
	@$(SUBMAKE) -C $(RVXTRASF) clean
