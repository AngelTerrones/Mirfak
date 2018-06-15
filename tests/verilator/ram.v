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
// Title       : RAM
// Project     : Mirfak
// Description : Dualport wishbone memory
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module ram #(
             parameter ADDR_WIDTH = 22,
             parameter BASE_ADDR  = 32'h0000_0000
             )(
               // Instruction
               // verilator lint_off UNUSED
               input wire [31:0] iwbs_addr_i,
               // verilator lint_on UNUSED
               input wire        iwbs_cyc_i,
               input wire        iwbs_stb_i,
               output reg [31:0] iwbs_dat_o,
               output reg        iwbs_ack_o,
               // Data
               // verilator lint_off UNUSED
               input wire [31:0] dwbs_addr_i,
               // verilator lint_on UNUSED
               input wire [31:0] dwbs_dat_i,
               input wire [ 3:0] dwbs_sel_i,
               input wire        dwbs_cyc_i,
               input wire        dwbs_stb_i,
               input wire        dwbs_we_i,
               output reg [31:0] dwbs_dat_o,
               output reg        dwbs_ack_o
               );
    //--------------------------------------------------------------------------
    localparam BYTES = 2**ADDR_WIDTH;
    //
    reg [7:0]               mem[0:BYTES - 1] /*verilator public*/;
    wire [ADDR_WIDTH - 1:0] i_addr;
    wire [ADDR_WIDTH - 1:0] d_addr;
    wire                    i_access;
    wire                    d_access;
    // read instructions
    assign i_addr   = {iwbs_addr_i[ADDR_WIDTH - 1:2], 2'b0};
    assign i_access = iwbs_addr_i[31:ADDR_WIDTH] == BASE_ADDR[31:ADDR_WIDTH];
    always @(*) begin
        iwbs_dat_o = 32'hx;
        if (i_access) begin
            iwbs_dat_o[7:0]    = mem[i_addr + 0];
            iwbs_dat_o[15:8]   = mem[i_addr + 1];
            iwbs_dat_o[23:16]  = mem[i_addr + 2];
            iwbs_dat_o[31:24]  = mem[i_addr + 3];
        end
        //
        iwbs_ack_o = iwbs_cyc_i && iwbs_stb_i && i_access;
    end
    // read/write data
    assign d_addr   = {dwbs_addr_i[ADDR_WIDTH - 1:2], 2'b0};
    assign d_access = dwbs_addr_i[31:ADDR_WIDTH] == BASE_ADDR[31:ADDR_WIDTH];
    always @(*) begin
        dwbs_dat_o = 32'hx;
        if (dwbs_we_i && d_access) begin
            if (dwbs_sel_i[0]) mem[d_addr + 0] = dwbs_dat_i[0+:8];
            if (dwbs_sel_i[1]) mem[d_addr + 1] = dwbs_dat_i[8+:8];
            if (dwbs_sel_i[2]) mem[d_addr + 2] = dwbs_dat_i[16+:8];
            if (dwbs_sel_i[3]) mem[d_addr + 3] = dwbs_dat_i[24+:8];
        end else begin
            dwbs_dat_o[7:0]    = mem[d_addr + 0];
            dwbs_dat_o[15:8]   = mem[d_addr + 1];
            dwbs_dat_o[23:16]  = mem[d_addr + 2];
            dwbs_dat_o[31:24]  = mem[d_addr + 3];
        end
        //
        dwbs_ack_o = dwbs_cyc_i && dwbs_stb_i && d_access;
    end
    //--------------------------------------------------------------------------
endmodule
