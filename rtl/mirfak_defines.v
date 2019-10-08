// -----------------------------------------------------------------------------
// Copyright (C) 2019 Angel Terrones <angelterrones@gmail.com>
// -----------------------------------------------------------------------------

`ifndef M_DEFINES
`define M_DEFINES

// -----------------------------------------------------------------------------
// Opcodes
parameter OPCODE_LUI    = 7'b0110111;
parameter OPCODE_AUIPC  = 7'b0010111;
parameter OPCODE_JAL    = 7'b1101111;
parameter OPCODE_JALR   = 7'b1100111;
parameter OPCODE_BRANCH = 7'b1100011;
parameter OPCODE_LOAD   = 7'b0000011;
parameter OPCODE_STORE  = 7'b0100011;
parameter OPCODE_OPIMM  = 7'b0010011;
parameter OPCODE_OP     = 7'b0110011;
parameter OPCODE_FENCE  = 7'b0001111;
parameter OPCODE_SYSTEM = 7'b1110011;
// -----------------------------------------------------------------------------
// CSR
parameter CYCLE      = 12'hC00;
parameter INSTRET    = 12'hC02;
parameter CYCLEH     = 12'hC80;
parameter INSTRETH   = 12'hC82;
parameter MVENDORID  = 12'hF11;
parameter MARCHID    = 12'hF12;
parameter MIMPID     = 12'hF13;
parameter MHARTID    = 12'hF14;
parameter MSTATUS    = 12'h300;
parameter MISA       = 12'h301;
parameter MEDELEG    = 12'h302;
parameter MIDELEG    = 12'h303;
parameter MIE        = 12'h304;
parameter MTVEC      = 12'h305;
parameter MCOUNTEREN = 12'h306;
parameter MSCRATCH   = 12'h340;
parameter MEPC       = 12'h341;
parameter MCAUSE     = 12'h342;
parameter MTVAL      = 12'h343;
parameter MIP        = 12'h344;
parameter MCYCLE     = 12'hB00;
parameter MINSTRET   = 12'hB02;
parameter MCYCLEH    = 12'hB80;
parameter MINSTRETH  = 12'hB82;
// -----------------------------------------------------------------------------
// Exception cause
parameter E_INST_ADDR_MISALIGNED      = 4'd0;
parameter E_INST_ACCESS_FAULT         = 4'd1;
parameter E_ILLEGAL_INST              = 4'd2;
parameter E_BREAKPOINT                = 4'd3;
parameter E_LOAD_ADDR_MISALIGNED      = 4'd4;
parameter E_LOAD_ACCESS_FAULT         = 4'd5;
parameter E_STORE_AMO_ADDR_MISALIGNED = 4'd6;
parameter E_STORE_AMO_ACCESS_FAULT    = 4'd7;
parameter E_ECALL_FROM_U              = 4'd8;
parameter E_ECALL_FROM_S              = 4'd9;
parameter E_ECALL_FROM_M              = 4'd11;
parameter I_U_SOFTWARE                = 4'd0;
parameter I_S_SOFTWARE                = 4'd1;
parameter I_M_SOFTWARE                = 4'd3;
parameter I_U_TIMER                   = 4'd4;
parameter I_S_TIMER                   = 4'd5;
parameter I_M_TIMER                   = 4'd7;
parameter I_U_EXTERNAL                = 4'd8;
parameter I_S_EXTERNAL                = 4'd9;
parameter I_M_EXTERNAL                = 4'd11;
// -----------------------------------------------------------------------------
//NOP
parameter NOP = 32'h33;
// -----------------------------------------------------------------------------
// Control: ALU
parameter ADDER_OP_ADD   = 1'b0;
parameter ADDER_OP_SUB   = 1'b1;
parameter LOGIC_OP_AND   = 2'b00;
parameter LOGIC_OP_OR    = 2'b01;
parameter LOGIC_OP_XOR   = 2'b10;
parameter SHIFT_OP_LL    = 2'b00;
parameter SHIFT_OP_LR    = 2'b10;
parameter SHIFT_OP_AR    = 2'b11;
parameter COMPARE_LT     = 1'b0;
parameter COMPARE_LTU    = 1'b1;
parameter ALU_OP_ADDER   = 2'b00;
parameter ALU_OP_LOGIC   = 2'b01;
parameter ALU_OP_SHIFT   = 2'b10;
parameter ALU_OP_COMPARE = 2'b11;
// LSU
parameter LSU_TYPE_BYTE  = 2'b00;
parameter LSU_TYPE_HALF  = 2'b01;
parameter LSU_TYPE_WORD  = 2'b10;
// Forwarding
parameter FWD_ID_SEL = 2'b00;
parameter FWD_EX_SEL = 2'b01;
parameter FWD_WB_SEL = 2'b10;
// Data select
parameter A_RF_SEL   = 2'b00;
parameter A_PC_SEL   = 2'b01;
parameter A_PC4_SEL  = 2'b10;
parameter A_ZERO_SEL = 2'b11;
parameter B_RF_SEL   = 2'b00;
parameter B_IMM_SEL  = 2'b01;
parameter B_4_SEL    = 2'b10;
parameter B_ZERO_SEL = 2'b11;
// WB data sel
parameter WB_ALU_SEL = 2'b00;
parameter WB_LSU_SEL = 2'b01;
parameter WB_CSR_SEL = 2'b10;
parameter WB_PC4_SEL = 2'b11;
// CSR CMD
parameter CSR_CMD_NONE  = 2'b00;
parameter CSR_CMD_WRITE = 2'b01;
parameter CSR_CMD_SET   = 2'b10;
parameter CSR_CMD_CLEAR = 2'b11;
// Control fields
`define CTRL_SZ          31:0
`define CTRL_INVALID     31:31
`define CTRL_IS_MULDIV   30:30
`define CTRL_FENCEI      29:29
`define CTRL_ECALL_BREAK 28:28
`define CTRL_RF_WE       27:27
`define CTRL_IS_J        26:26
`define CTRL_BGEU        25:25
`define CTRL_BLTU        24:24
`define CTRL_BGE         23:23
`define CTRL_BLT         22:22
`define CTRL_BNE         21:21
`define CTRL_BEQ         20:20
`define CTRL_CSR_CMD     19:18
`define CTRL_MEM_RW      17:17
`define CTRL_MEM_EN      16:16
`define CTRL_ALU_TYPE    15:14
`define CTRL_ALU_CMP     13:13
`define CTRL_ALU_SHIFT   12:12
`define CTRL_ALU_LOGIC   11:10
`define CTRL_ALU_ADD     9:9
`define CTRL_SEL_WB      8:7
`define CTRL_SEL_IMM     6:4
`define CTRL_SEL_OP_B    3:2
`define CTRL_SEL_OP_A    1:0

`endif
