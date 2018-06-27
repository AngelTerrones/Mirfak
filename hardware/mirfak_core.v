// -----------------------------------------------------------------------------
// Copyright (C) 2018 Angel Terrones <angelterrones@gmail.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// -----------------------------------------------------------------------------
// Title       : Top level module
// Project     : Mirfak
// Description : Top level module of the RISC-V core.
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

`include "mirfak_defines.v"

module mirfak_core #(
                     parameter [31:0] HART_ID         = 0,
                     parameter [31:0] RESET_ADDR      = 32'h8000_0000,
                     parameter [0:0]  ENABLE_COUNTERS = 1,
                     parameter [0:0]  ENABLE_M_ISA    = 1,
                     parameter        UCONTROL        = "ucontrol.list"
                     )(
                       input wire         clk_i,
                       input wire         rst_i,
                       // wishbone instruction port
                       output wire [31:0] iwbm_addr_o,
                       output wire        iwbm_cyc_o,
                       output wire        iwbm_stb_o,
                       input wire [31:0]  iwbm_dat_i,
                       input wire         iwbm_ack_i,
                       input wire         iwbm_err_i,
                       // wishbone data port
                       output wire [31:0] dwbm_addr_o,
                       output wire [31:0] dwbm_dat_o,
                       output wire [ 3:0] dwbm_sel_o,
                       output wire        dwbm_cyc_o,
                       output wire        dwbm_stb_o,
                       output wire        dwbm_we_o,
                       input wire [31:0]  dwbm_dat_i,
                       input wire         dwbm_ack_i,
                       input wire         dwbm_err_i,
                       // external interrupts interface
                       input wire         xint_meip_i,
                       input wire         xint_mtip_i,
                       input wire         xint_msip_i
                       );
    //--------------------------------------------------------------------------
    wire [31:0]     id_pc;
    wire [31:0]     id_pc4;
    wire [31:0]     id_instruction;
    wire            id_if_exception;
    wire [3:0]      id_if_xcause;
    wire            id_bubble;
    wire [31:0]     pc_bj;
    wire [31:0]     pc_except;
    wire [31:0]     pc_xret;
    wire            if_ready;
    wire [`CTRL_SZ] id_control;
    wire [31:0]     ex_pc;
    wire [31:0]     ex_pc4;
    wire [31:0]     ex_instruction;
    wire            ex_exception;
    wire [3:0]      ex_xcause;
    wire            ex_bubble;
    wire [31:0]     ex_operand_a;
    wire [31:0]     ex_operand_b;
    wire [31:0]     ex_lsu_wdata;
    wire [`CTRL_SZ] ex_control;
    wire [31:0]     wb_pc;
    wire [31:0]     wb_pc4;
    wire            wb_ex_exception;
    wire [3:0]      wb_ex_xcause;
    wire            wb_bubble;
    wire [31:0]     wb_alu_result;
    wire [31:0]     wb_lsu_wdata;
    // verilator lint_off UNUSED
    wire [`CTRL_SZ] wb_control;
    wire [31:0]     wb_instruction;
    // verilator lint_on UNUSED
    wire [31:0]     csr_rdata;
    wire            take_branch;
    reg [31:0]      wb_wdata;
    wire [1:0]      id_fwd_a_sel;
    wire [1:0]      id_fwd_b_sel;
    wire [31:0]     ex_fwd_data;
    wire [31:0]     wb_lsu_rdata;
    wire            lsu_busy;
    wire            lsu_misaligned;
    wire            lsu_ld_err;
    wire            lsu_st_err;
    reg             wb_exception;
    reg [3:0]       wb_xcause;
    reg [31:0]      csr_wdata;
    wire            csr_exception;
    wire            xinterrupt;
    wire [3:0]      xint_xcause;
    wire            wb_xret;
    wire            xcall;
    wire            xbreak;
    wire [31:0]     ex_mtval;
    wire            xint;
    wire [31:0]     wb_ex_mtval;
    reg [31:0]      wb_mtval;
    wire            ex_is_mem_or_csr;
    wire            ex_busy;
    wire            id_busy;
    //
    wire            ifid_enable;
    wire            ifid_clear;
    wire            idex_enable;
    wire            idex_clear;
    wire            exwb_enable;
    wire            exwb_clear;
    //
    assign wb_xret = wb_control[`CTRL_ECALL_BREAK] && wb_instruction[24:20] == 5'b00010;
    assign ex_is_mem_or_csr = ex_control[`CTRL_MEM_EN] || |ex_control[`CTRL_CSR_CMD];
    //
    mirfak_if_stage #(.RESET_ADDR(RESET_ADDR)
                      ) ifstage (// Outputs
                                 .id_pc_o            (id_pc),
                                 .id_pc4_o           (id_pc4),
                                 .id_instruction_o   (id_instruction),
                                 .id_if_exception_o  (id_if_exception),
                                 .id_if_xcause_o     (id_if_xcause),
                                 .id_bubble          (id_bubble),
                                 .iwbm_addr_o        (iwbm_addr_o),
                                 .iwbm_cyc_o         (iwbm_cyc_o),
                                 .iwbm_stb_o         (iwbm_stb_o),
                                 // Inputs
                                 .clk_i              (clk_i),
                                 .rst_i              (rst_i),
                                 .pc_bj_i            (pc_bj),
                                 .pc_except_i        (pc_except),
                                 .pc_xret_i          (pc_xret),
                                 .pc_bj_sel_i        (take_branch),
                                 .pc_except_sel_i    (wb_exception),
                                 .pc_xret_sel_i      (wb_xret),
                                 .iwbm_dat_i         (iwbm_dat_i),
                                 .iwbm_ack_i         (iwbm_ack_i),
                                 .iwbm_err_i         (iwbm_err_i),
                                 .ifid_enable_i      (ifid_enable),
                                 .if_abort_fetch_i   (wb_exception || take_branch || wb_xret),
                                 .if_halt_fetch_i    (id_busy),
                                 .ifid_clear_i       (ifid_clear),
                                 .if_ready_o         (if_ready)
                                 );
    //
    mirfak_id_stage idstage (// Outputs
                             .ex_pc_o            (ex_pc),
                             .ex_pc4_o           (ex_pc4),
                             .ex_instruction_o   (ex_instruction),
                             .ex_exception_o     (ex_exception),
                             .ex_xcause_o        (ex_xcause),
                             .ex_mtval_o         (ex_mtval),
                             .ex_bubble_o        (ex_bubble),
                             .ex_operand_a_o     (ex_operand_a),
                             .ex_operand_b_o     (ex_operand_b),
                             .ex_lsu_wdata_o     (ex_lsu_wdata),
                             .ex_control_o       (ex_control),
                             .pc_bj_target_o     (pc_bj),
                             .take_branch_o      (take_branch),
                             // Inputs
                             .clk_i              (clk_i),
                             .rst_i              (rst_i),
                             .id_pc_i            (id_pc),
                             .id_pc4_i           (id_pc4),
                             .id_instruction_i   (id_instruction),
                             .id_if_exception_i  (id_if_exception),
                             .id_if_xcause_i     (id_if_xcause),
                             .id_bubble          (id_bubble),
                             .id_control_i       (id_control),
                             .wb_waddr_i         (wb_instruction[11:7]),
                             .wb_wdata_i         (wb_wdata),
                             .wb_wen_i           (wb_control[`CTRL_RF_WE] && !wb_exception),
                             .id_fwd_a_sel_i     (id_fwd_a_sel),
                             .id_fwd_b_sel_i     (id_fwd_b_sel),
                             .ex_fwd_data_i      (ex_fwd_data),
                             .wb_fwd_data_i      (wb_wdata),
                             .idex_enable_i      (idex_enable),
                             .idex_clear_i       (idex_clear)
                             );
    //
    mirfak_ex_stage #(.ENABLE_MULTDIV(ENABLE_M_ISA)
                      ) exstage (// Outputs
                                 .wb_pc_o            (wb_pc),
                                 .wb_pc4_o           (wb_pc4),
                                 .wb_instruction_o   (wb_instruction),
                                 .wb_ex_exception_o  (wb_ex_exception),
                                 .wb_ex_xcause_o     (wb_ex_xcause),
                                 .wb_ex_mtval_o      (wb_ex_mtval),
                                 .wb_bubble_o        (wb_bubble),
                                 .wb_alu_result_o    (wb_alu_result),
                                 .wb_lsu_wdata_o     (wb_lsu_wdata),
                                 .wb_control_o       (wb_control),
                                 .ex_fwd_data_o      (ex_fwd_data),
                                 .ex_busy_o          (ex_busy),
                                 // Inputs
                                 .clk_i              (clk_i),
                                 .rst_i              (rst_i),
                                 .ex_pc_i            (ex_pc),
                                 .ex_pc4_i           (ex_pc4),
                                 .ex_instruction_i   (ex_instruction),
                                 .ex_exception_i     (ex_exception),
                                 .ex_xcause_i        (ex_xcause),
                                 .ex_mtval_i         (ex_mtval),
                                 .ex_bubble_i        (ex_bubble),
                                 .ex_operand_a_i     (ex_operand_a),
                                 .ex_operand_b_i     (ex_operand_b),
                                 .ex_lsu_wdata_i     (ex_lsu_wdata),
                                 .ex_control_i       (ex_control),
                                 .ex_abort_muldiv    (wb_exception || wb_xret),
                                 .exwb_enable_i      (exwb_enable),
                                 .exwb_clear_i       (exwb_clear)
                                 );
    // WB stage
    mirfak_load_store_unit lsu (// Outputs
                                .lsu_rdata_o       (wb_lsu_rdata),
                                .lsu_busy_o        (lsu_busy),
                                .lsu_misaligned_o  (lsu_misaligned),
                                .lsu_ld_err_o      (lsu_ld_err),
                                .lsu_st_err_o      (lsu_st_err),
                                .dwbm_addr_o       (dwbm_addr_o),
                                .dwbm_dat_o        (dwbm_dat_o),
                                .dwbm_sel_o        (dwbm_sel_o),
                                .dwbm_cyc_o        (dwbm_cyc_o),
                                .dwbm_stb_o        (dwbm_stb_o),
                                .dwbm_we_o         (dwbm_we_o),
                                // Inputs
                                .lsu_address_i     (wb_alu_result),
                                .lsu_wdata_i       (wb_lsu_wdata),
                                .lsu_op_i          (wb_control[`CTRL_MEM_RW]),
                                .lsu_en_i          (wb_control[`CTRL_MEM_EN]),
                                .lsu_data_type_i   (wb_instruction[13:12]),
                                .lsu_data_sign_ext (!wb_instruction[14]),
                                .lsu_is_xint_i     (xint),
                                .dwbm_dat_i        (dwbm_dat_i),
                                .dwbm_ack_i        (dwbm_ack_i),
                                .dwbm_err_i        (dwbm_err_i)
                                );
    //
    mirfak_csr #(.HART_ID(HART_ID),
                 .ENABLE_COUNTERS(ENABLE_COUNTERS),
                 .ENABLE_M_ISA(ENABLE_M_ISA)
                 ) csr (// Outputs
                        .csr_rdata_o         (csr_rdata),
                        .csr_exception_o     (csr_exception),
                        .xinterrupt_o        (xinterrupt),
                        .xint_xcause_o       (xint_xcause),
                        .pc_except_o         (pc_except),
                        .pc_xret_o           (pc_xret),
                        // Inputs
                        .clk_i               (clk_i),
                        .rst_i               (rst_i),
                        .xint_meip_i         (xint_meip_i),
                        .xint_mtip_i         (xint_mtip_i),
                        .xint_msip_i         (xint_msip_i),
                        .csr_addr_i          (wb_instruction[31:20]),
                        .csr_cmd_i           (wb_control[`CTRL_CSR_CMD]),
                        .csr_rs1_zero_i      (wb_instruction[19:15] == 0),
                        .csr_wdata_i         (csr_wdata),
                        .wb_exception_i      (wb_exception),
                        .wb_xret_i           (wb_xret),
                        .wb_exception_pc_i   (wb_pc),
                        .wb_xcause_i         (wb_xcause),
                        .wb_mtval_i          (wb_mtval),
                        .wb_bubble_i         (wb_bubble));
    // Control
    mirfak_controller #(.ENABLE_MULTDIV(ENABLE_M_ISA),
                        .UCONTROL(UCONTROL)
                        ) control (// Outputs
                                   .id_control_o     (id_control),
                                   .id_fwd_a_sel_o   (id_fwd_a_sel),
                                   .id_fwd_b_sel_o   (id_fwd_b_sel),
                                   .exwb_enable_o    (exwb_enable),
                                   .exwb_clear_o     (exwb_clear),
                                   .idex_enable_o    (idex_enable),
                                   .idex_clear_o     (idex_clear),
                                   .ifid_enable_o    (ifid_enable),
                                   .ifid_clear_o     (ifid_clear),
                                   // Inputs
                                   .id_instruction_i   (id_instruction),
                                   .ex_wa_i            (ex_instruction[11:7]),
                                   .ex_wen_i           (ex_control[`CTRL_RF_WE]),
                                   .ex_is_mem_or_csr_i (ex_is_mem_or_csr),
                                   .wb_wa_i            (wb_instruction[11:7]),
                                   .wb_wen_i           (wb_control[`CTRL_RF_WE] && !wb_exception),
                                   .wb_lsu_busy_i      (lsu_busy),
                                   .wb_csr_busy_i      (1'b0), // TODO: remove
                                   .ex_busy_i          (ex_busy),
                                   .id_busy_i          (id_busy),
                                   .if_ready_i         (if_ready),
                                   .wb_exception_i     (wb_exception),
                                   .wb_xret_i          (wb_xret),
                                   .id_bj_taken_i      (take_branch)
                                   );
    // Handle final exception @ WB stage
    always @(*) begin
        case (wb_control[`CTRL_SEL_WB])
            WB_ALU_SEL: wb_wdata = wb_alu_result;
            WB_LSU_SEL: wb_wdata = wb_lsu_rdata;
            WB_CSR_SEL: wb_wdata = csr_rdata;
            WB_PC4_SEL: wb_wdata = wb_pc4;
        endcase
        //
        csr_wdata = (wb_instruction[14]) ? {27'b0, wb_instruction[19:15]}: wb_alu_result;
    end
    //
    assign id_busy = id_control[`CTRL_FENCEI] && ((ex_control[`CTRL_MEM_EN] && ex_control[`CTRL_MEM_RW]) ||
                                                  (wb_control[`CTRL_MEM_EN] && wb_control[`CTRL_MEM_RW]));
    assign xint    = xinterrupt && !wb_bubble;
    assign xcall   = wb_control[`CTRL_ECALL_BREAK] && wb_instruction[31:20] == 12'b000000000000;
    assign xbreak  = wb_control[`CTRL_ECALL_BREAK] && wb_instruction[31:20] == 12'b000000000001;
    always @(*) begin
        wb_exception = |{wb_ex_exception, csr_exception, lsu_misaligned, lsu_ld_err, lsu_st_err, xcall, xbreak, xint};
        case (1'b1)
            xint:            begin wb_xcause = xint_xcause;                                                                wb_mtval = 0;              end
            wb_ex_exception: begin wb_xcause = wb_ex_xcause;                                                               wb_mtval = wb_ex_mtval;    end
            lsu_misaligned:  begin wb_xcause = (wb_instruction[5]) ? E_STORE_AMO_ADDR_MISALIGNED : E_LOAD_ADDR_MISALIGNED; wb_mtval = wb_alu_result;  end
            lsu_ld_err:      begin wb_xcause = E_LOAD_ACCESS_FAULT;                                                        wb_mtval = wb_alu_result;  end
            lsu_st_err:      begin wb_xcause = E_STORE_AMO_ACCESS_FAULT;                                                   wb_mtval = wb_alu_result;  end
            csr_exception:   begin wb_xcause = E_ILLEGAL_INST;                                                             wb_mtval = wb_instruction; end
            xcall:           begin wb_xcause = E_ECALL_FROM_M;                                                             wb_mtval = 0;              end
            xbreak:          begin wb_xcause = E_BREAKPOINT;                                                               wb_mtval = wb_pc;          end
            default:         begin wb_xcause = 4'bx;                                                                       wb_mtval = 32'bx;          end
        endcase
    end
    //--------------------------------------------------------------------------
endmodule
// EOF
