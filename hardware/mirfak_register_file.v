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
// Title       : Integer Register File
// Project     : Mirfak
// Description : Register file: 32x32-bit wide registers, with r0 hardwired to
//               zero
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_register_file (
                             input wire        clk_i,
                             // read port 1
                             input wire [4:0]  raddr_a_i,
                             output reg [31:0] rdata_a_o,
                             // read port 2
                             input wire [4:0]  raddr_b_i,
                             output reg [31:0] rdata_b_o,
                             // write port
                             input wire [4:0]  waddr_i,
                             input wire [31:0] wdata_i,
                             input wire        wen_i
                             );
    //--------------------------------------------------------------------------
    reg [31:0] mem[0:31];
    // read
    always @(*) begin
        rdata_a_o = (|raddr_a_i) ? mem[raddr_a_i] : 32'b0;
        rdata_b_o = (|raddr_b_i) ? mem[raddr_b_i] : 32'b0;
    end
    // write
    always @(posedge clk_i) begin
        if (wen_i && |waddr_i) begin
            mem[waddr_i] <= wdata_i;
        end
    end
    //--------------------------------------------------------------------------
endmodule
