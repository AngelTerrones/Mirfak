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
// Title       : Load Store Unit
// Project     : Mirfak
// Description : Handle access to the Wishbone data port
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_load_store_unit (
                               // pipeline interface
                               input wire [31:0] lsu_address_i,
                               input wire [31:0] lsu_wdata_i,
                               input wire        lsu_op_i,
                               input wire        lsu_en_i,
                               input wire [1:0]  lsu_data_type_i,
                               input wire        lsu_data_sign_ext,
                               output reg [31:0] lsu_rdata_o,
                               output reg        lsu_busy_o,
                               // error
                               input wire        lsu_is_xint_i,
                               output reg        lsu_misaligned_o,
                               output reg        lsu_ld_err_o,
                               output reg        lsu_st_err_o,
                               // Data port
                               output reg [31:0] dwbm_addr_o,
                               output reg [31:0] dwbm_dat_o,
                               output reg [ 3:0] dwbm_sel_o,
                               output reg        dwbm_cyc_o,
                               output reg        dwbm_stb_o,
                               output reg        dwbm_we_o,
                               input wire [31:0] dwbm_dat_i,
                               input wire        dwbm_ack_i,
                               input wire        dwbm_err_i
                               );
    //--------------------------------------------------------------------------
    reg [31:0] mdat_o, mdat_i;
    reg [3:0]  msel_o;
    wire       mem_en;
    //
    assign mem_en = lsu_en_i && !(|{lsu_misaligned_o, lsu_ld_err_o, lsu_st_err_o, lsu_is_xint_i});
    // exception
    always @(*) begin
        case (lsu_data_type_i)
            LSU_TYPE_HALF: lsu_misaligned_o = lsu_en_i && lsu_address_i[0];
            LSU_TYPE_WORD: lsu_misaligned_o = lsu_en_i && |lsu_address_i[1:0];
            default:       lsu_misaligned_o = 0;
        endcase
        lsu_ld_err_o = lsu_en_i && !lsu_op_i && dwbm_err_i;
        lsu_st_err_o = lsu_en_i && lsu_op_i && dwbm_err_i;
    end
    // data format: write
    always @(*) begin
        case (lsu_data_type_i)
            LSU_TYPE_BYTE: begin
                mdat_o = {4{lsu_wdata_i[7:0]}};
                msel_o = 4'b0001 << lsu_address_i[1:0];
            end
            LSU_TYPE_HALF: begin
                mdat_o = {2{lsu_wdata_i[15:0]}};
                msel_o = lsu_address_i[1] ? 4'b1100 : 4'b0011;
            end
            default: begin
                mdat_o = lsu_wdata_i;
                msel_o = 4'b1111;
            end
        endcase
    end // always @ (*)
    // data format: read
    always @(*) begin
        // verilator lint_off WIDTH
        case (lsu_data_type_i)
            LSU_TYPE_BYTE: begin
                case (lsu_address_i[1:0])
                    2'b00: mdat_i = {{24{lsu_data_sign_ext && dwbm_dat_i[7]}}, dwbm_dat_i[7:0]};
                    2'b01: mdat_i = {{24{lsu_data_sign_ext && dwbm_dat_i[15]}}, dwbm_dat_i[15:8]};
                    2'b10: mdat_i = {{24{lsu_data_sign_ext && dwbm_dat_i[23]}}, dwbm_dat_i[23:16]};
                    2'b11: mdat_i = {{24{lsu_data_sign_ext && dwbm_dat_i[31]}}, dwbm_dat_i[31:24]};
                endcase
            end
            LSU_TYPE_HALF: begin
                case (lsu_address_i[1])
                    1'b0: mdat_i = {{16{lsu_data_sign_ext && dwbm_dat_i[15]}}, dwbm_dat_i[15:0]};
                    1'b1: mdat_i = {{16{lsu_data_sign_ext && dwbm_dat_i[31]}}, dwbm_dat_i[31:16]};
                endcase
            end
            LSU_TYPE_WORD: begin
                mdat_i = dwbm_dat_i;
            end
            default: begin
                mdat_i = 32'bx;
            end
        endcase
        // verilator lint_on WIDTH
    end
    //
    always @(*) begin
        dwbm_addr_o  = lsu_address_i;
        dwbm_dat_o   = mdat_o;
        dwbm_sel_o   = msel_o;
        dwbm_we_o    = mem_en && lsu_op_i;
        dwbm_cyc_o   = mem_en;
        dwbm_stb_o   = mem_en;
        //
        lsu_rdata_o  = mdat_i;
        //
        lsu_busy_o   = mem_en && !(dwbm_ack_i || dwbm_err_i);
    end
    //--------------------------------------------------------------------------
endmodule
