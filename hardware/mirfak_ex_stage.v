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
// Title       : EX stage
// Project     : Mirfak
// Description : Execute stage and EXWB interface
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_ex_stage #(parameter [0:0]  ENABLE_MULTDIV = 1
                         )(
                           input wire            clk_i,
                           input wire            rst_i,
                           // EX stage inputs
                           input wire [31:0]     ex_pc_i,
                           input wire [31:0]     ex_pc4_i,
                           input wire [31:0]     ex_instruction_i,
                           input wire            ex_exception_i,
                           input wire [3:0]      ex_xcause_i,
                           input wire [31:0]     ex_mtval_i,
                           input wire            ex_bubble_i,
                           input wire [31:0]     ex_operand_a_i,
                           input wire [31:0]     ex_operand_b_i,
                           input wire [31:0]     ex_lsu_wdata_i,
                           input wire [`CTRL_SZ] ex_control_i,
                           // EX -> WB
                           output reg [31:0]     wb_pc_o,
                           output reg [31:0]     wb_pc4_o,
                           output reg [31:0]     wb_instruction_o,
                           output reg            wb_ex_exception_o,
                           output reg [3:0]      wb_ex_xcause_o,
                           output reg [31:0]     wb_ex_mtval_o,
                           output reg            wb_bubble_o,
                           output reg [31:0]     wb_alu_result_o,
                           output reg [31:0]     wb_lsu_wdata_o,
                           output reg [`CTRL_SZ] wb_control_o,
                           // forwarding
                           output reg [31:0]     ex_fwd_data_o,
                           // pipeline control
                           output reg            ex_busy_o,
                           input wire            ex_abort_muldiv,
                           input wire            exwb_enable_i,
                           input wire            exwb_clear_i
                           );
    //--------------------------------------------------------------------------
    //
    wire [31:0] alu_result;
    wire [31:0] mult_result;
    wire        mult_ack;
    wire [31:0] div_result;
    wire        div_ack;
    //
    mirfak_alu alu (// Outputs
                    .result_o     (alu_result),
                    // Inputs
                    .operand_a_i  (ex_operand_a_i),
                    .operand_b_i  (ex_operand_b_i),
                    .adder_op_i   (ex_control_i[`CTRL_ALU_ADD] && ex_instruction_i[30]),
                    .logic_op_i   (ex_control_i[`CTRL_ALU_LOGIC]),
                    .shift_op_i   ({ex_control_i[`CTRL_ALU_SHIFT], ex_instruction_i[30]}),
                    .compare_op_i (ex_control_i[`CTRL_ALU_CMP]),
                    .alu_op_i     (ex_control_i[`CTRL_ALU_TYPE]));
    //
    generate if (ENABLE_MULTDIV) begin
        //
        mirfak_multiplier mult (// Outputs
                                .mult_result    (mult_result),
                                .mult_ack       (mult_ack),
                                // Inputs
                                .clk_i          (clk_i),
                                .rst_i          (rst_i),
                                .mult_op1       (ex_operand_a_i),
                                .mult_op2       (ex_operand_b_i),
                                .mult_cmd       (ex_instruction_i[13:12]),
                                .mult_enable    (ex_control_i[`CTRL_IS_MULDIV] && !ex_instruction_i[14]),
                                .mult_abort     (ex_abort_muldiv));
        //
        mirfak_divider div (// Outputs
                            .div_result         (div_result),
                            .div_ack            (div_ack),
                            // Inputs
                            .clk_i              (clk_i),
                            .rst_i              (rst_i),
                            .div_op1            (ex_operand_a_i),
                            .div_op2            (ex_operand_b_i),
                            .div_cmd            (ex_instruction_i[13:12]),
                            .div_enable         (ex_control_i[`CTRL_IS_MULDIV] && ex_instruction_i[14]),
                            .div_abort          (ex_abort_muldiv));
    end else begin
        // verilator lint_off UNUSED
        wire __x__ = ex_abort_muldiv;
        // verilator lint_on UNUSED
        assign mult_result = 32'bx;
        assign mult_ack    = 0;
        assign div_result  = 32'bx;
        assign div_ack     = 0;
    end endgenerate
    //
    always @(*) begin
        ex_busy_o     = ex_control_i[`CTRL_IS_MULDIV] && !mult_ack && !div_ack;
        case ({ex_control_i[`CTRL_IS_MULDIV], ex_instruction_i[14]})
            2'b10:   ex_fwd_data_o  = mult_result;
            2'b11:   ex_fwd_data_o  = div_result;
            default: ex_fwd_data_o  = alu_result;
        endcase
    end
    //
    always @(posedge clk_i) begin
        if (rst_i || exwb_clear_i) begin
            wb_pc_o           <= 0;
            wb_pc4_o          <= 0;
            wb_instruction_o  <= NOP;
            wb_ex_exception_o <= 0;
            wb_bubble_o       <= 0;
            wb_control_o      <= 0;
        end else if (exwb_enable_i) begin
            wb_pc_o           <= ex_pc_i;
            wb_pc4_o          <= ex_pc4_i;
            wb_instruction_o  <= ex_instruction_i;
            wb_ex_exception_o <= ex_exception_i;
            wb_ex_xcause_o    <= ex_xcause_i;
            wb_ex_mtval_o     <= ex_mtval_i;
            wb_bubble_o       <= ex_bubble_i;
            wb_alu_result_o   <= ex_fwd_data_o;
            wb_lsu_wdata_o    <= ex_lsu_wdata_i;
            wb_control_o      <= ex_control_i;
        end
    end
    //--------------------------------------------------------------------------
endmodule //
