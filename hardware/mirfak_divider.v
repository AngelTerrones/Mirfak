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
// Title       : Divider
// Project     : Mirfak
// Description : 32-bit divider.
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_divider (
                       input wire clk_i,
                       input wire rst_i,
                       // pipeline interface
                       input wire [31:0] div_op1,
                       input wire [31:0] div_op2,
                       input wire [1:0]  div_cmd,
                       input wire        div_enable,
                       output reg [31:0] div_result,
                       output reg        div_ack
                       );
    //--------------------------------------------------------------------------
    wire       is_div, is_divu, is_rem;
    reg [31:0] dividend;
    reg [62:0] divisor;
    reg [31:0] quotient;
    reg [31:0] quotient_mask;
    reg        start, start_q, running, outsign;
    //
    assign is_div  = div_cmd == 2'b00;
    assign is_divu = div_cmd == 2'b01;
    assign is_rem  = div_cmd == 2'b10;
    //
    always @(posedge clk_i) begin
        if (rst_i) begin
            start   <= 0;
            start_q <= 0;
        end else begin
            start   <= div_enable;
            start_q <= start;
        end
    end
    //
    always @(posedge clk_i) begin
        if (rst_i) begin
            div_ack <= 0;
            running <= 0;
        end else begin
            div_ack <= 0;
            // verilator lint_off WIDTH
            if (start && !start_q) begin
                running       <= 1;
                dividend      <= ((is_div || is_rem) && div_op1[31]) ? -div_op1 : div_op1;
                divisor       <= (((is_div || is_rem) && div_op2[31]) ? -div_op2 : div_op2) << 31;
                outsign       <= (is_div && (div_op1[31] != div_op2[31]) && |div_op2) || (is_rem && div_op1[31]);
                quotient      <= 0;
                quotient_mask <= 1 << 31;
            end else if (quotient_mask == 0 && running) begin
                running <= 0;
                div_ack <= 1;
                if (is_div || is_divu) begin
                    div_result <= outsign ? -quotient : quotient;
                end else begin
                    div_result <= outsign ? -dividend : dividend;
                end
            end else begin
                if (divisor <= dividend) begin
                    dividend <= dividend - divisor;
                    quotient <= quotient | quotient_mask;
                end
                divisor <= divisor >> 1;
                quotient_mask <= quotient_mask >> 1;
            end
            // verilator lint_on WIDTH
        end
    end
    //--------------------------------------------------------------------------
endmodule
