# MIRFAK - A pipelined RISC-V CPU

Mirfak is a CPU core that implements the [RISC-V RV32I Instruction Set](http://riscv.org/).

Algol is free and open hardware licensed under the [MIT license](https://en.wikipedia.org/wiki/MIT_License).

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [MIRFAK - A pipelined RISC-V CPU](#mirfak---a-pipelined-risc-v-cpu)
    - [CPU core details](#cpu-core-details)
    - [Software Details](#software-details)
    - [Directory Layout](#directory-layout)
    - [RISC-V toolchain](#risc-v-toolchain)
    - [Simulation](#simulation)
        - [Dependencies for simulation](#dependencies-for-simulation)
    - [License](#license)

<!-- markdown-toc end -->

## CPU core details

- RISC-V RV32I ISA.
- Single-issue, in-order, four-stage pipeline datapath.
- Separate instruction and data ports.
- No MMU.
- No cache.
- No FPU. Software-base floating point support (toolchain).
- Machine [privilege mode](https://riscv.org/specifications/privileged-isa/). Current version: v1.10.
- Support for external interrupts, as described in the [privilege mode manual](https://riscv.org/specifications/privileged-isa/).
- [Wishbone B4](https://www.ohwr.org/attachments/179/wbspec_b4.pdf) Bus Interface.
- Vendor-independent code.

## Software Details

- Simulation done in C++ using [Verilator](https://www.veripool.org/wiki/verilator).
- [Toolchain](http://riscv.org/software-tools/) using gcc.
- [Validation suit](http://riscv.org/software-tools/riscv-tests/) written in assembly.
- [Benchmarks](http://riscv.org/software-tools/riscv-tests/) written in C.

## Directory Layout

- `README.md`: This file.
- `hardware`: CPU source files written in Verilog.
- `documentation`: LaTeX source files for the CPU manual (TODO).
- `software`: Support libraries for the CPU, in C.
- `tests`: Test environment for the CPU.
    - `benchmarks`: Basic benchmarks written in C. Taken from [riscv-tests](http://riscv.org/software-tools/riscv-tests/) (git rev b747a10**).
    - `extra-tests`: Tests for the support libraries, and external interrupts.
    - `riscv-tests`: Basic instruction-level tests. Taken from [riscv-tests](http://riscv.org/software-tools/riscv-tests/) (git rev b747a10**).
    - `verilator`: C++ testbench for the CPU validation.

## RISC-V toolchain

The easy way to get the toolchain is to download the binary installer from the
[GNU MCU Eclipse](https://gnu-mcu-eclipse.github.io/) project.

The version used to simulate the design is the [Embedded GCC v7.2.0-3-20180506](https://gnu-mcu-eclipse.github.io/blog/2018/05/06/riscv-none-gcc-v7-2-0-3-20180506-released/)

## Simulation
### Dependencies for simulation

- [Verilator](https://www.veripool.org/wiki/verilator) for simulation. Minimum version: 3.884.
- A RISC-V toolchain, to compile the validation tests and benchmarks.

### Compile assembly tests and benchmarks
The instruction-level tests are from the [riscv-tests](http://riscv.org/software-tools/riscv-tests/) repository.
The original makefile has been modified to use the toolchain from [GNU MCU Eclipse](https://gnu-mcu-eclipse.github.io/).

To compile the RISC-V instruction-level tests, benchmarks and extra-tests:

> $ make compile-tests

### Simulate the CPU
To perform the simulation, execute the following commands in the root folder of the project:

- To execute all the tests, without VCD dumps:

> $ make run-mirfak-tests

- To execute the C++ model with a single `.elf` file:

> $ Mirfak.exe --frequency <core frequency> --timeout <max simulation time> --file <filename> [--trace] [--trace-directory <trace directory>] [--trace-name <VCD name>]

## License

Copyright (c) 2018 Angel Terrones (<angelterrones@gmail.com>).

Release under the [MIT License](MITlicense.md).
