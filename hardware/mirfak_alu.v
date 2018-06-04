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
// Title       : ALU
// Project     : Mirfak
// Description : Arithmetic logic unit of the processor core
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_alu (
                   // Inputs
                   input wire [31:0] operand_a_i,
                   input wire [31:0] operand_b_i,
                   output reg [31:0] result_o,
                   // control
                   input wire        adder_op_i,
                   input wire [1:0]  logic_op_i,
                   input wire [1:0]  shift_op_i,
                   input wire        compare_op_i,
                   input wire [1:0]  alu_op_i
                   );
    //--------------------------------------------------------------------------
    reg [31:0] adder_o, logic_o, shift_o, compare_o;
    //
    always @(*) begin
        // Adder
        case (adder_op_i)
            ADDER_OP_ADD: adder_o = operand_a_i + operand_b_i;
            ADDER_OP_SUB: adder_o = operand_a_i - operand_b_i;
        endcase
        // logic
        case (logic_op_i)
            LOGIC_OP_AND: logic_o = operand_a_i & operand_b_i;
            LOGIC_OP_OR:  logic_o = operand_a_i | operand_b_i;
            LOGIC_OP_XOR: logic_o = operand_a_i ^ operand_b_i;
            default:      logic_o = 32'bx;
        endcase
        // shift
        case (shift_op_i)
            SHIFT_OP_LL: shift_o = operand_a_i << operand_b_i[4:0];
            SHIFT_OP_LR: shift_o = operand_a_i >> operand_b_i[4:0];
            SHIFT_OP_AR: shift_o = $signed(operand_a_i) >>> operand_b_i[4:0];
            default:     shift_o = 32'bx;
        endcase
        // compare
        case (compare_op_i)
            COMPARE_LT:  compare_o = {31'b0, operand_a_i < operand_b_i};
            COMPARE_LTU: compare_o = {31'b0, $signed(operand_a_i) < $signed(operand_b_i)};
        endcase
        // final mux
        case (alu_op_i)
            ALU_OP_ADDER:   result_o = adder_o;
            ALU_OP_LOGIC:   result_o = logic_o;
            ALU_OP_SHIFT:   result_o = shift_o;
            ALU_OP_COMPARE: result_o = compare_o;
        endcase
    end
    //--------------------------------------------------------------------------
endmodule
