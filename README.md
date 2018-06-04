MIRFAK - A pipelined RISC-V CPU
===============================

Mirfak is a CPU core that implements the [RISC-V RV32I Instruction Set](http://riscv.org/).

Algol is free and open hardware licensed under the [MIT license](https://en.wikipedia.org/wiki/MIT_License).

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [MIRFAK - A pipelined RISC-V CPU](#mirfak---a-pipelined-risc-v-cpu)
    - [Dependencies](#dependencies)
    - [CPU core details](#cpu-core-details)
    - [Software Details](#software-details)
    - [Directory Layout](#directory-layout)
    - [RISC-V toolchain](#risc-v-toolchain)
    - [License](#license)

<!-- markdown-toc end -->

Dependencies
------------
- [Verilator](https://www.veripool.org/wiki/verilator) for simulation. Minimum version: 3.922.
- A RISC-V toolchain, to compile the validation tests and benchmarks.

CPU core details
-----------------
- RISC-V RV32I ISA.
- Machine [privilege mode](https://riscv.org/specifications/privileged-isa/). Current version: v1.10.
- Four-stage pipelined datapath.
- Dual memory ports (Instruction and Data) using the [Wishbone B4](https://www.ohwr.org/attachments/179/wbspec_b4.pdf) Interface.

Software Details
----------------
- Simulation done in C++ using [Verilator](https://www.veripool.org/wiki/verilator).
- [Toolchain](http://riscv.org/software-tools/) using gcc.
- [Validation suit](http://riscv.org/software-tools/riscv-tests/) written in assembly.
- [Benchmarks](http://riscv.org/software-tools/riscv-tests/) written in C.

Directory Layout
----------------
- `README.md`: This file.
- `hardware`: CPU source files written in Verilog.
- `documentation`: LaTeX source files for the CPU manuals (TODO).
- `software`: Support libraries for the CPU, in C.
- `tests`: Test environment for the CPU.
    - `benchmarks`: Basic benchmarks written in C. Taken from [riscv-tests](http://riscv.org/software-tools/riscv-tests/) (git rev b747a10**).
    - `extra-tests`: Tests for the support libraries, and external interrupts.
    - `riscv-tests`: Basic instruction-level tests. Taken from [riscv-tests](http://riscv.org/software-tools/riscv-tests/) (git rev b747a10**).
    - `verilator`: C++ testbench for the CPU validation.

RISC-V toolchain
----------------
The easy way to get the toolchain is to download a pre-compiled version from the
[GNU MCU Eclipse](https://gnu-mcu-eclipse.github.io/) project.

The version used to validate this core is the [Embedded GCC v7.2.0-1-20171109](https://gnu-mcu-eclipse.github.io/blog/2017/11/09/riscv-none-gcc-v7-2-0-1-20171109-released/)

License
-------
Copyright (c) 2018 Angel Terrones (<angelterrones@gmail.com>).

Release under the [MIT License](MITlicense.md).
