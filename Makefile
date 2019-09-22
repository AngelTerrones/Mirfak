# ------------------------------------------------------------------------------
# Copyright (c) 2019 Angel Terrones <angelterrones@gmail.com>
# ------------------------------------------------------------------------------
SHELL=bash

# ------------------------------------------------------------------------------
SUBMAKE			= $(MAKE) --no-print-directory
ROOT			= $(shell pwd)
BFOLDER			= $(ROOT)/build
VCOREDIR		= $(ROOT)/simulator/verilator
PYTHON			= python3

# Compliance tests
RVCOMPLIANCE = $(ROOT)/tests/riscv-compliance
# xint test
RVXTRASF       = $(ROOT)/tests/extra-tests

# export variables
export RISCV_PREFIX ?= $(RVGCC_PATH)/riscv64-unknown-elf-
export ROOT
export TARGET_FOLDER = $(VCOREDIR)

# ------------------------------------------------------------------------------
# targets
# ------------------------------------------------------------------------------
help:
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "Please, choose one target:"
	@echo -e "- install-compliance:         Clone the riscv-compliance test."
	@echo -e "- build-core:                 Build C++ core model."
	@echo -e "- core-sim-compliance:        Execute the compliance tests."
	@echo -e "- core-sim-compliance-rv32i:  Execute the RV32I compliance tests."
	@echo -e "- core-sim-compliance-rv32im: Execute the RV32IM compliance tests."
	@echo -e "- core-sim-compliance-rv32mi: Execute machine mode compliance tests."
	@echo -e "- core-sim-compliance-rv32ui: Execute the RV32I compliance tests (redundant)."
	@echo -e "--------------------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# Install repo
# ------------------------------------------------------------------------------
install-compliance:
	@./scripts/install_compliance
# ------------------------------------------------------------------------------
# compliance tests
# ------------------------------------------------------------------------------
core-sim-compliance: core-sim-compliance-rv32i core-sim-compliance-rv32ui core-sim-compliance-rv32im core-sim-compliance-rv32mi

core-sim-compliance-rv32i: build-core
	@$(SUBMAKE) -C $(RVCOMPLIANCE) variant RISCV_TARGET=mirfak RISCV_DEVICE=rv32i RISCV_ISA=rv32i

core-sim-compliance-rv32im: build-core
	@$(SUBMAKE) -C $(RVCOMPLIANCE) variant RISCV_TARGET=mirfak RISCV_DEVICE=rv32im RISCV_ISA=rv32im

core-sim-compliance-rv32mi: build-core
	@$(SUBMAKE) -C $(RVCOMPLIANCE) variant RISCV_TARGET=mirfak RISCV_DEVICE=rv32mi RISCV_ISA=rv32mi

core-sim-compliance-rv32ui: build-core
	@$(SUBMAKE) -C $(RVCOMPLIANCE) variant RISCV_TARGET=mirfak RISCV_DEVICE=rv32ui RISCV_ISA=rv32ui
# ------------------------------------------------------------------------------
# verilate and build
# ------------------------------------------------------------------------------
build-core:
	@mkdir -p $(BFOLDER)
	+@$(SUBMAKE) -C $(VCOREDIR)

# ------------------------------------------------------------------------------
# clean
# ------------------------------------------------------------------------------
clean:
	@$(SUBMAKE) -C $(VCOREDIR) clean

distclean: clean
	@$(SUBMAKE) -C $(RVCOMPLIANCE) clean
	@rm -rf $(BFOLDER)
