# MIRFAK - A pipelined RISC-V CPU

Mirfak is a CPU core that implements the [RISC-V RV32I Instruction
Set](http://riscv.org/).

Mirfak is free and open hardware licensed under the [MIT
license](https://en.wikipedia.org/wiki/MIT_License).

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [MIRFAK - A pipelined RISC-V CPU](#mirfak---a-pipelined-risc-v-cpu)
    - [CPU core details](#cpu-core-details)
    - [Project Details](#project-details)
    - [Directory Layout](#directory-layout)
    - [RISC-V toolchain](#risc-v-toolchain)
    - [Verilog module parameters](#verilog-module-parameters)
    - [Simulation](#simulation)
        - [Dependencies for simulation](#dependencies-for-simulation)
        - [Compile assembly tests and benchmarks](#compile-assembly-tests-and-benchmarks)
        - [Simulate the CPU](#simulate-the-cpu)
            - [Parameters of the C++ model](#parameters-of-the-c-model)
    - [License](#license)

<!-- markdown-toc end -->

## CPU core details

- RISC-V RV32IM ISA.
- Single-issue, in-order, four-stage pipeline datapath.
- Separate instruction and data ports.
- No MMU.
- No cache.
- No FPU. Software-base floating point support (toolchain).
- Machine [privilege mode](https://riscv.org/specifications/privileged-isa/).
  Current version: v1.10.
- Support for external interrupts, as described in the [privilege mode
  manual](https://riscv.org/specifications/privileged-isa/).
- [Wishbone B4](https://www.ohwr.org/attachments/179/wbspec_b4.pdf) Bus Interface.
- Vendor-independent code.

## Project Details

- Simulation done in C++ using
  [Verilator](https://www.veripool.org/wiki/verilator).
- [Toolchain](http://riscv.org/software-tools/) using gcc.
- [Validation suit](http://riscv.org/software-tools/riscv-tests/) written in
  assembly.
- [Benchmarks](http://riscv.org/software-tools/riscv-tests/) written in C.

## Directory Layout

- `README.md`: This file.
- `hardware`: CPU source files written in Verilog.
- `documentation`: LaTeX source files for the CPU manual (TODO).
- `software`: Support libraries for the CPU, in C.
- `tests`: Test environment for the CPU.
    - `benchmarks`: Basic benchmarks written in C. Taken from
      [riscv-tests](http://riscv.org/software-tools/riscv-tests/) (git rev
      b747a10).
    - `extra-tests`: Tests for the support libraries, and external interrupts.
    - `riscv-tests`: Basic instruction-level tests. Taken from
      [riscv-tests](http://riscv.org/software-tools/riscv-tests/) (git rev
      b747a10).
    - `verilator`: C++ testbench for the CPU validation.

## RISC-V toolchain

The easy way to get the toolchain is to download the binary installer from the
[GNU MCU Eclipse](https://gnu-mcu-eclipse.github.io/) project.

The version used to simulate the design is the [Embedded GCC
v7.2.0-3-20180506](https://gnu-mcu-eclipse.github.io/blog/2018/05/06/riscv-none-gcc-v7-2-0-3-20180506-released/)

## Verilog module parameters

The following parameters can be used to configure the cpu core.

- **HART_ID (default = 0)**: This sets the ID of the core (for multi-core applications).
- **RESET_ADDR (default = 0x80000000)**: The start address of the program.
- **ENABLE_COUNTERS (default = 1)**: Add support for the `CYCLE[H]` and `INSTRET[H]` counters. If set to zero,
reading the counters will return zero or a random number.
- **ENABLE\_M\_ISA (default = 1)**: Enable hardware support for the RV32M ISA.
- **UCONTROL (default = "ucontrol.list")**: Path to a plain text file with the definition of the control signals, in binary
format, for each supported instruction.

## Simulation
### Dependencies for simulation

- [Verilator](https://www.veripool.org/wiki/verilator) for simulation. Minimum
  version: 3.884.
- A RISC-V toolchain, to compile the validation tests and benchmarks.

### Compile assembly tests and benchmarks
The instruction-level tests are from the
[riscv-tests](http://riscv.org/software-tools/riscv-tests/) repository.
The original makefile has been modified to use the toolchain from [GNU MCU
Eclipse](https://gnu-mcu-eclipse.github.io/).

To compile the RISC-V instruction-level tests, benchmarks and extra-tests:

> $ make compile-tests

### Simulate the CPU
To perform the simulation, execute the following commands in the root folder of
the project:

- To execute all the tests, without VCD dumps:

> $ make run-mirfak-tests

- To execute the C++ model with a single `.elf` file:

> $ Mirfak.exe --frequency [core frequency] --timeout [max simulation time]
> --mem-delay [cycles] --file [filename] --trace --trace-directory [trace
> directory] --trace-name [VCD name]

#### Parameters of the C++ model

- **frequency**: Frequency for system clock.
- **timeout**: Maximum simulation time before aborting.
- **mem-delay**: Number of cycles before assertion of the ACK signal.
- **file**: RISC-V ELF file to execute.
- **trace (optional)**: Enable VCD dumps.
- **trace-directory (optional)**: Folder to store the VCD file. Default is the current
  directory.
- **trace-name (optional)**: Name of the VCD file. Default is the name of the project plus
  the name of the ELF file.

## License

Copyright (c) 2018 Angel Terrones (<angelterrones@gmail.com>).

Release under the [MIT License](MITlicense.md).
