# ------------------------------------------------------------------------------
# Copyright (c) 2018 Angel Terrones <angelterrones@gmail.com>
# Project: Mirfak
# ------------------------------------------------------------------------------
include tests/verilator/pprint.mk
SHELL=bash

.SUBMAKE := $(MAKE) --no-print-directory
.PWD:=$(shell pwd)
.BFOLDER:=build
.RVTESTSF:=tests/riscv-tests
.RVBENCHMARKSF:=tests/benchmarks
.RVXTRATESTSF:=tests/extra-tests
.MK_MIRFAK:=tests/verilator/build.mk
.MIRFAKCMD:=$(.BFOLDER)/Mirfak.exe --frequency 10e6 --timeout 1000000000 --file
.UCGEN := hardware/ucontrolgen.py
.PYTHON:=python3
.UCONTROL = $(.BFOLDER)/ucontrol.mem

# ------------------------------------------------------------------------------
# targets
# ------------------------------------------------------------------------------
help:
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "Please, choose one target:"
	@echo -e "- compile-tests:    Compile RISC-V assembler tests, benchmarks and extra tests."
	@echo -e "- verilate-mirfak:  Generate C++ core model."
	@echo -e "- build-mirfak:     Build C++ core model."
	@echo -e "- run-mirfak-tests: Execute assembler tests, benchmarks and extra tests."
	@echo -e "--------------------------------------------------------------------------------"

compile-tests:
	+@$(.SUBMAKE) -C $(.RVTESTSF)
	+@$(.SUBMAKE) -C $(.RVBENCHMARKSF)
	+@$(.SUBMAKE) -C $(.RVXTRATESTSF)

# ------------------------------------------------------------------------------
# verilate and build
$(.UCONTROL): $(.UCGEN)
	@mkdir -p $(.BFOLDER)
	@$(.PYTHON) $(.UCGEN) $(.UCONTROL)

verilate-mirfak: $(.UCONTROL)
	@printf "%b" "$(.MSJ_COLOR)Building RTL (Modules) for Verilator$(.NO_COLOR)\n"
	@mkdir -p $(.BFOLDER)
	+@$(.SUBMAKE) -f $(.MK_MIRFAK) build-vlib BUILD_DIR=$(.BFOLDER) UFILE=$(.UCONTROL)

build-mirfak: verilate-mirfak
	+@$(.SUBMAKE) -f $(.MK_MIRFAK) build-core BUILD_DIR=$(.BFOLDER)

# ------------------------------------------------------------------------------
# verilator tests
run-mirfak-tests: compile-tests build-mirfak
	@$(eval .RVTESTS:=$(shell find $(.RVTESTSF) -name "rv32ui*.elf" -o -name "rv32mi*.elf" ! -name "*breakpoint*.elf"))
	@for file in $(.RVTESTS); do \
		$(.MIRFAKCMD) $$file > /dev/null; \
		if [ $$? -eq 0 ]; then \
			printf "%-50b %b\n" $$file "$(.OK_COLOR)$(.OK_STRING)$(.NO_COLOR)"; \
		else \
			printf "%-50s %b" $$file "$(.ERROR_COLOR)$(.ERROR_STRING)$(.NO_COLOR)\n"; \
		fi; \
	done
	@$(eval .RVBENCHMARKS:=$(shell find $(.RVBENCHMARKSF) -name "*.riscv"))
	@for file in $(.RVBENCHMARKS); do \
		$(.MIRFAKCMD) $$file > /dev/null; \
		if [ $$? -eq 0 ]; then \
			printf "%-50b %b\n" $$file "$(.OK_COLOR)$(.OK_STRING)$(.NO_COLOR)"; \
		else \
			printf "%-50s %b" $$file "$(.ERROR_COLOR)$(.ERROR_STRING)$(.NO_COLOR)\n"; \
		fi; \
	done
	@$(eval .RVXTRATESTS:=$(shell find $(.RVXTRATESTSF) -name "*.riscv"))
	@for file in $(.RVXTRATESTS); do \
		$(.MIRFAKCMD) $$file > /dev/null; \
		if [ $$? -eq 0 ]; then \
			printf "%-50b %b\n" $$file "$(.OK_COLOR)$(.OK_STRING)$(.NO_COLOR)"; \
		else \
			printf "%-50s %b" $$file "$(.ERROR_COLOR)$(.ERROR_STRING)$(.NO_COLOR)\n"; \
		fi; \
	done
# ------------------------------------------------------------------------------
# clean
# ------------------------------------------------------------------------------
clean:
	@rm -rf $(.BFOLDER)

distclean: clean
	@find . | grep -E "(__pycache__|\.pyc|\.pyo|\.cache)" | xargs rm -rf
	@$(.SUBMAKE) -C $(.RVTESTSF) clean
	@$(.SUBMAKE) -C $(.RVBENCHMARKSF) clean
	@$(.SUBMAKE) -C $(.RVXTRATESTSF) clean

.PHONY: compile-tests compile-benchmarks run-tests run-benchmarks clean distclean
