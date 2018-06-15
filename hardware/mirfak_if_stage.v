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
// Title       : Instruction Fetch Stage
// Project     : Mirfak
// Description : Select next PC. Handling the Wishbone instruction port
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_if_stage #(
                         parameter [31:0] RESET_ADDR = 32'h8000_0000
                         )(
                           input wire        clk_i,
                           input wire        rst_i,
                           // New pc from pipeline
                           input wire [31:0] pc_bj_i,
                           input wire [31:0] pc_except_i,
                           input wire [31:0] pc_xret_i,
                           // New pc selector
                           input wire        pc_bj_sel_i,
                           input wire        pc_except_sel_i,
                           input wire        pc_xret_sel_i,
                           // IF -> ID
                           output reg [31:0] id_pc_o,
                           output reg [31:0] id_pc4_o,
                           output reg [31:0] id_instruction_o,
                           output reg        id_if_exception_o,
                           output reg [3:0]  id_if_xcause_o,
                           output reg        id_bubble,
                           // Instruction port
                           output reg [31:0] iwbm_addr_o,
                           output reg        iwbm_cyc_o,
                           output reg        iwbm_stb_o,
                           input wire [31:0] iwbm_dat_i,
                           input wire        iwbm_ack_i,
                           input wire        iwbm_err_i,
                           // pipeline control
                           input wire        ifid_enable_i,
                           input wire        ifid_clear_i,
                           input wire        if_abort_fetch_i,
                           input wire        if_restart_i,
                           output reg        if_ready_o
                           );
    //--------------------------------------------------------------------------
    //
    localparam ifu_state_reset = 4'b0001;
    localparam ifu_state_fetch = 4'b0010;
    localparam ifu_state_stall = 4'b0100;
    localparam ifu_state_kill  = 4'b1000;
    reg [3:0] ifu_state;
    reg       instr_sel;
    //
    reg [31:0] pc, pc4, npc;
    reg [31:0] instruction_q;
    reg        exception;
    reg [3:0]  xcause;
    // select the new PC
    always @(*) begin
        pc4 = pc + 32'h4;
        case (1'b1)
            pc_except_sel_i: npc = pc_except_i;
            pc_xret_sel_i:   npc = pc_xret_i;
            pc_bj_sel_i:     npc = pc_bj_i;
            default:         npc = pc4;
        endcase
    end
    // PC register
    always @(posedge clk_i) begin
        if (rst_i) begin
            pc <= RESET_ADDR;
        end else if (if_restart_i) begin
        end else if (ifid_enable_i || if_abort_fetch_i) begin
            pc <= npc;
        end
    end
    // IF -> ID
    always @(posedge clk_i) begin
        if (rst_i || ifid_clear_i) begin
            id_pc_o           <= 0;
            id_pc4_o          <= 0;
            id_instruction_o  <= NOP;
            id_if_exception_o <= 0;
            id_if_xcause_o    <= 0;
            id_bubble         <= 1;
        end else if (ifid_enable_i) begin
            id_pc_o           <= pc;
            id_pc4_o          <= pc4;
            id_instruction_o  <= (instr_sel) ? instruction_q : iwbm_dat_i;
            id_if_exception_o <= exception;
            id_if_xcause_o    <= xcause;
            id_bubble         <= 0; // TODO: verify
        end
    end
    // exception
    always @(*) begin
        exception = |pc[1:0] || iwbm_err_i;
        case (1'b1)
            iwbm_err_i: xcause  = E_INST_ACCESS_FAULT;
            default:    xcause  = E_INST_ADDR_MISALIGNED;
        endcase
    end
    // pipeline handler
    always @(*) begin
        if_ready_o  = iwbm_ack_i || iwbm_err_i || instr_sel;
    end
    // WBM Instruction port
    // TODO: recheck logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            ifu_state  <= ifu_state_reset;
            instr_sel  <= 0;
            iwbm_cyc_o <= 0;
            iwbm_stb_o <= 0;
        end else begin
            case (ifu_state)
                ifu_state_reset: begin
                    ifu_state  <= ifu_state_fetch;
                    iwbm_cyc_o <= 1'b1;
                    iwbm_stb_o <= 1'b1;
                end
                ifu_state_fetch: begin
                    if (if_abort_fetch_i || if_restart_i) begin
                        ifu_state     <= ifu_state_kill;
                        iwbm_cyc_o    <= 1'b0;
                        iwbm_stb_o    <= 1'b0;
                        instruction_q <= NOP;
                        instr_sel     <= 1'b0;
                    end else if ((iwbm_ack_i || iwbm_err_i) && !ifid_enable_i) begin
                        ifu_state     <= ifu_state_stall;
                        iwbm_cyc_o    <= 1'b0;
                        iwbm_stb_o    <= 1'b0;
                        instruction_q <= (iwbm_err_i) ? NOP : iwbm_dat_i;
                        instr_sel     <= 1'b1;
                    end
                end
                ifu_state_stall: begin
                    if (if_abort_fetch_i) begin
                        ifu_state     <= ifu_state_kill;
                        iwbm_cyc_o    <= 1'b0;
                        iwbm_stb_o    <= 1'b0;
                        instruction_q <= NOP;
                        instr_sel     <= 1'b0;
                    end else if (ifid_enable_i) begin
                        ifu_state     <= ifu_state_fetch;
                        iwbm_cyc_o    <= 1'b1;
                        iwbm_stb_o    <= 1'b1;
                        instruction_q <= NOP;
                        instr_sel     <= 1'b0;
                    end
                end
                ifu_state_kill : begin
                    if (!if_abort_fetch_i && !if_restart_i) begin
                        ifu_state     <= ifu_state_fetch;
                        iwbm_cyc_o    <= 1'b1;
                        iwbm_stb_o    <= 1'b1;
                        instruction_q <= NOP;
                        instr_sel     <= 1'b0;
                    end
                end
                default: begin
                    ifu_state  <= ifu_state_reset;
                    iwbm_cyc_o <= 1'b0;
                    iwbm_stb_o <= 1'b0;
                    instr_sel  <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        iwbm_addr_o  = pc;
    end
    //--------------------------------------------------------------------------
endmodule
