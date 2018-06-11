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
.MAX_DELAY = 1

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
	$(eval .RVTESTS:=$(shell find $(.RVTESTSF) -name "rv32ui*.elf" -o -name "rv32um*.elf" -o -name "rv32mi*.elf" ! -name "*breakpoint*.elf"))
	$(eval .RVBENCHMARKS:=$(shell find $(.RVBENCHMARKSF) -name "*.riscv"))
	$(eval .RVXTRATESTS:=$(shell find $(.RVXTRATESTSF) -name "*.riscv"))
	@for delay in {0..$(.MAX_DELAY)}; do													\
		printf "%b\n" "$(.WARN_COLOR)Testing for MEM_DELAY: $$delay$(.NO_COLOR)";			\
		for file in $(.RVTESTS) $(.RVBENCHMARKS) $(.RVXTRATESTS); do						\
			$(.MIRFAKCMD) $$file --mem-delay $$delay > /dev/null;							\
			if [ $$? -eq 0 ]; then															\
				printf "%-50b %b\n" $$file "$(.OK_COLOR)$(.OK_STRING)$(.NO_COLOR)";			\
			else																			\
				printf "%-50s %b" $$file "$(.ERROR_COLOR)$(.ERROR_STRING)$(.NO_COLOR)\n";	\
			fi;																				\
		done;																				\
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
