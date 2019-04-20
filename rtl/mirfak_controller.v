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
// Title       : Main controller
// Project     : Mirfak
// Description : Pipeline controller: datapath, forwarding and stalls
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_controller #(
                           parameter [0:0]  ENABLE_MULTDIV = 1,
                           parameter UCONTROL = ""
                           )(
                             input wire [31:0]      id_instruction_i,
                             // control signal to ID stage
                             output wire [`CTRL_SZ] id_control_o,
                             // fwd
                             input wire [4:0]       ex_wa_i,
                             input wire             ex_wen_i,
                             input wire             ex_is_mem_or_csr_i,
                             input wire [4:0]       wb_wa_i,
                             input wire             wb_wen_i,
                             output reg [1:0]       id_fwd_a_sel_o,
                             output reg [1:0]       id_fwd_b_sel_o,
                             // Busy signals
                             input wire             wb_lsu_busy_i,
                             input wire             wb_csr_busy_i,
                             input wire             ex_busy_i,
                             input wire             id_busy_i,
                             input wire             if_ready_i,
                             // kill sources
                             input wire             wb_exception_i,
                             input wire             wb_xret_i,
                             input wire             id_bj_taken_i,
                             // Pipeline control
                             output reg             exwb_enable_o,
                             output reg             exwb_clear_o,
                             output reg             idex_enable_o,
                             output reg             idex_clear_o,
                             output reg             ifid_enable_o,
                             output reg             ifid_clear_o
                             );
    //--------------------------------------------------------------------------
    wire [4:0] rs1, rs2;
    wire       fwd_a_ex, fwd_a_wb;
    wire       fwd_b_ex, fwd_b_wb;
    wire       wb_ready, ex_ready, id_ready, if_ready;
    // forwarding rules
    assign rs1      = id_instruction_i[19:15];
    assign rs2      = id_instruction_i[24:20];
    assign fwd_a_ex = |ex_wa_i && rs1 == ex_wa_i && ex_wen_i;
    assign fwd_b_ex = |ex_wa_i && rs2 == ex_wa_i && ex_wen_i;
    assign fwd_a_wb = |wb_wa_i && rs1 == wb_wa_i && wb_wen_i;
    assign fwd_b_wb = |wb_wa_i && rs2 == wb_wa_i && wb_wen_i;

    always @(*) begin
        case (1'b1)
            fwd_a_ex: id_fwd_a_sel_o = FWD_EX_SEL;
            fwd_a_wb: id_fwd_a_sel_o = FWD_WB_SEL;
            default:  id_fwd_a_sel_o = FWD_ID_SEL;
        endcase
        case (1'b1)
            fwd_b_ex: id_fwd_b_sel_o = FWD_EX_SEL;
            fwd_b_wb: id_fwd_b_sel_o = FWD_WB_SEL;
            default:  id_fwd_b_sel_o = FWD_ID_SEL;
        endcase
    end
    //
    assign wb_ready = !wb_lsu_busy_i && !wb_csr_busy_i;
    assign ex_ready = wb_ready && !ex_busy_i;
    assign id_ready = ex_ready && !id_busy_i && !((fwd_a_ex || fwd_b_ex) && ex_is_mem_or_csr_i);
    assign if_ready = id_ready && if_ready_i;
    always @(*) begin
        exwb_enable_o = ex_ready;
        idex_enable_o = id_ready;
        ifid_enable_o = if_ready;
        //
        exwb_clear_o = (!ex_ready && wb_ready) || wb_exception_i || wb_xret_i;
        idex_clear_o = (!id_ready && ex_ready) || wb_exception_i || wb_xret_i;
        ifid_clear_o = (!if_ready && id_ready) || wb_exception_i || wb_xret_i || id_bj_taken_i;
    end
    //
    mirfak_decoder #(.ENABLE_MULTDIV(ENABLE_MULTDIV),
                     .UCONTROL(UCONTROL)
                     ) decoder (// Outputs
                                .id_control_o     (id_control_o),
                                // Inputs
                                .id_instruction_i (id_instruction_i));
    //--------------------------------------------------------------------------
endmodule
