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
// Title       : ID stage
// Project     : Mirfak
// Description : Instruction Decode stage, and IDEX interface
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_id_stage (
                        input wire            clk_i,
                        input wire            rst_i,
                        // IF stage inputs
                        input wire [31:0]     id_pc_i,
                        input wire [31:0]     id_pc4_i,
                        input wire [31:0]     id_instruction_i,
                        input wire            id_if_exception_i,
                        input wire [3:0]      id_if_xcause_i,
                        input wire            id_bubble,
                        // ID -> EX
                        output reg [31:0]     ex_pc_o,
                        output reg [31:0]     ex_pc4_o,
                        output reg [31:0]     ex_instruction_o,
                        output reg            ex_exception_o,
                        output reg [3:0]      ex_xcause_o,
                        output reg [31:0]     ex_mtval_o,
                        output reg            ex_bubble_o,
                        output reg [31:0]     ex_operand_a_o,
                        output reg [31:0]     ex_operand_b_o,
                        output reg [31:0]     ex_lsu_wdata_o,
                        output reg [`CTRL_SZ] ex_control_o,
                        // control
                        input wire [`CTRL_SZ] id_control_i,
                        // jumps
                        output reg [31:0]     pc_bj_target_o,
                        output reg            take_branch_o,
                        // write register file
                        input wire [4:0]      wb_waddr_i,
                        input wire [31:0]     wb_wdata_i,
                        input wire            wb_wen_i,
                        // forwarding
                        input wire [1:0]      id_fwd_a_sel_i,
                        input wire [1:0]      id_fwd_b_sel_i,
                        input wire [31:0]     ex_fwd_data_i,
                        input wire [31:0]     wb_fwd_data_i,
                        // pipeline control
                        input wire            idex_enable_i,
                        input wire            idex_clear_i
                       );
    //--------------------------------------------------------------------------
    wire [31:0] rdata_a, rdata_b;
    //
    reg [31:0]  fdata_a, fdata_b;
    reg [31:0]  operand_a, operand_b;
    wire        exception;
    reg [3:0]   xcause;
    wire        is_eq, is_lt, is_ltu;
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm_final;
    wire [31:0] pc_j_b, pc_jr;
    reg [31:0]  mtval;
    wire        bj_error;
    //
    mirfak_register_file regfile (// Outputs
                                  .rdata_a_o (rdata_a),
                                  .rdata_b_o (rdata_b),
                                  // Inputs
                                  .clk_i     (clk_i),
                                  .raddr_a_i (id_instruction_i[19:15]),
                                  .raddr_b_i (id_instruction_i[24:20]),
                                  .waddr_i   (wb_waddr_i),
                                  .wdata_i   (wb_wdata_i),
                                  .wen_i     (wb_wen_i));
    //
    // verilator lint_off WIDTH
    assign imm_i = $signed(id_instruction_i[31:20]);
    assign imm_s = $signed({id_instruction_i[31:25], id_instruction_i[11:7]});
    assign imm_b = $signed({id_instruction_i[31], id_instruction_i[7], id_instruction_i[30:25], id_instruction_i[11:8], 1'b0});
    assign imm_u = {id_instruction_i[31:12], {12{1'b0}}};
    assign imm_j = $signed({id_instruction_i[31], id_instruction_i[19:12], id_instruction_i[20], id_instruction_i[30:21], 1'b0});
    // verilator lint_on WIDTH
    always @(*) begin
        case (id_control_i[`CTRL_SEL_IMM])
            3'b000:  imm_final  = imm_i;
            3'b001:  imm_final  = imm_s;
            3'b010:  imm_final  = imm_b;
            3'b011:  imm_final  = imm_u;
            3'b100:  imm_final  = imm_j;
            default: imm_final  = 32'hx;
        endcase
    end
    //
    always @(*) begin
        // forwarding
        case (id_fwd_a_sel_i)
            FWD_ID_SEL: fdata_a = rdata_a;
            FWD_EX_SEL: fdata_a = ex_fwd_data_i;
            FWD_WB_SEL: fdata_a = wb_fwd_data_i;
            default:    fdata_a = 32'bx;
        endcase
        //
        case (id_fwd_b_sel_i)
            FWD_ID_SEL: fdata_b = rdata_b;
            FWD_EX_SEL: fdata_b = ex_fwd_data_i;
            FWD_WB_SEL: fdata_b = wb_fwd_data_i;
            default:    fdata_b = 32'bx;
        endcase
        // Data selection
        case (id_control_i[`CTRL_SEL_OP_A])
            A_RF_SEL:   operand_a = fdata_a;
            A_PC_SEL:   operand_a = id_pc_i;
            A_PC4_SEL:  operand_a = id_pc4_i;
            A_ZERO_SEL: operand_a = 32'b0;
        endcase
        //
        case (id_control_i[`CTRL_SEL_OP_B])
            B_RF_SEL:   operand_b = fdata_b;
            B_IMM_SEL:  operand_b = imm_final;
            B_4_SEL:    operand_b = 32'h4;
            B_ZERO_SEL: operand_b = 32'b0;
        endcase
    end
    //
    assign is_eq   = fdata_a == fdata_b;
    assign is_lt   = $signed(fdata_a) < $signed(fdata_b);
    assign is_ltu  = fdata_a < fdata_b;
    assign pc_j_b  = id_pc_i + (id_control_i[`CTRL_IS_J] ? imm_j : imm_b);
    assign pc_jr   = fdata_a + imm_i;
    always @(*) begin
        take_branch_o  = |{is_eq && id_control_i[`CTRL_BEQ], !is_eq && id_control_i[`CTRL_BNE],
                           is_lt && id_control_i[`CTRL_BLT], !is_lt && id_control_i[`CTRL_BGE],
                           is_ltu && id_control_i[`CTRL_BLTU], !is_ltu && id_control_i[`CTRL_BGEU],
                           id_control_i[`CTRL_IS_J]} && idex_enable_i;
        pc_bj_target_o  = (id_control_i[`CTRL_IS_J] && !id_instruction_i[3]) ? pc_jr & 32'hFFFFFFFE : pc_j_b;
    end
    //
    assign bj_error  = take_branch_o && |pc_bj_target_o[1:0];
    assign exception = id_if_exception_i || id_control_i[`CTRL_INVALID] || bj_error;
    always @(*) begin
        case (1'b1)
            id_if_exception_i: begin xcause = id_if_xcause_i;         mtval = id_pc_i;          end
            bj_error:          begin xcause = E_INST_ADDR_MISALIGNED; mtval = pc_bj_target_o;   end
            default:           begin xcause = E_ILLEGAL_INST;         mtval = id_instruction_i; end
        endcase
    end
    //
    always @(posedge clk_i) begin
        if (rst_i || idex_clear_i) begin
            ex_pc_o          <= 0;
            ex_pc4_o         <= 0;
            ex_instruction_o <= NOP;
            ex_exception_o   <= 0;
            ex_xcause_o      <= 0;
            ex_bubble_o      <= 1;
            ex_control_o     <= 0;
        end else if (idex_enable_i) begin
            ex_pc_o          <= id_pc_i;
            ex_pc4_o         <= id_pc4_i;
            ex_instruction_o <= id_instruction_i;
            ex_exception_o   <= exception;
            ex_xcause_o      <= xcause;
            ex_mtval_o       <= mtval;
            ex_bubble_o      <= id_bubble;
            ex_operand_a_o   <= operand_a;
            ex_operand_b_o   <= operand_b;
            ex_lsu_wdata_o   <= fdata_b;;
            ex_control_o     <= id_control_i;
        end
    end
    //--------------------------------------------------------------------------
endmodule
