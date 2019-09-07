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
// Title       : Instruction decoder
// Project     : Mirfak
// Description : Decode instruction, and generate datapath control signals
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

`include "mirfak_defines.v"

module mirfak_decoder #(
                        parameter [0:0]  ENABLE_MULTDIV = 1
                        )(// verilator lint_off UNUSED
                          input wire [31:0]     id_instruction_i,
                          // verilator lint_on UNUSED
                          output reg [`CTRL_SZ] id_control_o
                          );
    //--------------------------------------------------------------------------
    wire           is_lui, is_auipc, is_jal, is_jalr, is_branch, is_load;
    wire           is_store, is_ri, is_rr, is_fence, is_system, is_m;
    //
    assign is_lui     = id_instruction_i[6:0] == 7'b0110111;
    assign is_auipc   = id_instruction_i[6:0] == 7'b0010111;
    assign is_jal     = id_instruction_i[6:0] == 7'b1101111;
    assign is_jalr    = id_instruction_i[6:0] == 7'b1100111;
    assign is_branch  = id_instruction_i[6:0] == 7'b1100011;
    assign is_load    = id_instruction_i[6:0] == 7'b0000011;
    assign is_store   = id_instruction_i[6:0] == 7'b0100011;
    assign is_ri      = id_instruction_i[6:0] == 7'b0010011 && ((id_instruction_i[13:12] == 2'b01) ? (!id_instruction_i[31] && id_instruction_i[29:25] == 5'b00000) : 1);
    assign is_rr      = id_instruction_i[6:0] == 7'b0110011 && !id_instruction_i[31] && id_instruction_i[29:25] == 5'b00000;
    assign is_fence   = id_instruction_i[6:0] == 7'b0001111;
    assign is_system  = id_instruction_i[6:0] == 7'b1110011;
    assign is_m       = id_instruction_i[6:0] == 7'b0110011 && id_instruction_i[31:25] == 7'b0000001 && ENABLE_MULTDIV;

    always @(*) begin
        // upper bits: instruction type
        // low bits:   funct3
        case (1'b1)
            is_lui:    begin
                id_control_o = 32'b00001000000000000000000000110111;
            end
            is_auipc:  begin
                id_control_o = 32'b00001000000000000000000000110101;
            end
            is_jal:    begin
                id_control_o = 32'b00001100000000000000000111000101;
            end
            is_jalr:   begin
                id_control_o = 32'b00001100000000000000000110000100;
            end
            is_branch: begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o  = 32'b00000000000100000000000000100101;
                    3'b001: id_control_o  = 32'b00000000001000000000000000100101;
                    3'b100: id_control_o  = 32'b00000000010000000000000000100101;
                    3'b101: id_control_o  = 32'b00000000100000000000000000100101;
                    3'b110: id_control_o  = 32'b00000001000000000000000000100101;
                    3'b111: id_control_o  = 32'b00000010000000000000000000100101;
                    default: id_control_o = 32'b10000000000000000000000000000000;
                endcase
            end
            is_load:   begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o  = 32'b00001000000000010000000010000100;
                    3'b001: id_control_o  = 32'b00001000000000010000000010000100;
                    3'b010: id_control_o  = 32'b00001000000000010000000010000100;
                    3'b100: id_control_o  = 32'b00001000000000010000000010000100;
                    3'b101: id_control_o  = 32'b00001000000000010000000010000100;
                    default: id_control_o = 32'b10000000000000000000000000000000;
                endcase
            end
            is_store:  begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o  = 32'b00000000000000110000000000010100;
                    3'b001: id_control_o  = 32'b00000000000000110000000000010100;
                    3'b010: id_control_o  = 32'b00000000000000110000000000010100;
                    default: id_control_o = 32'b10000000000000000000000000000000;
                endcase
            end
            is_ri:     begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o = 32'b00001000000000000000000000000100; // addi
                    3'b001: id_control_o = 32'b00001000000000001000000000000100; // slli
                    3'b010: id_control_o = 32'b00001000000000001110000000000100; // slti
                    3'b011: id_control_o = 32'b00001000000000001100000000000100; // sltiu
                    3'b100: id_control_o = 32'b00001000000000000100100000000100; // xori
                    3'b101: id_control_o = 32'b00001000000000001001000000000100; // srli_srai
                    3'b110: id_control_o = 32'b00001000000000000100010000000100; // ori
                    3'b111: id_control_o = 32'b00001000000000000100000000000100; // andi
                endcase
            end
            is_rr:     begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o = 32'b00001000000000000000001000000000; // add_sub
                    3'b001: id_control_o = 32'b00001000000000001000000000000000; // sll
                    3'b010: id_control_o = 32'b00001000000000001110000000000000; // slt
                    3'b011: id_control_o = 32'b00001000000000001100000000000000; // sltu
                    3'b100: id_control_o = 32'b00001000000000000100100000000000; // xor
                    3'b101: id_control_o = 32'b00001000000000001001000000000000; // srl_sra
                    3'b110: id_control_o = 32'b00001000000000000100010000000000; // or
                    3'b111: id_control_o = 32'b00001000000000000100000000000000; // and
                endcase
            end
            is_fence:  begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o  = 32'b00000000000000000000000000000000;
                    3'b001: id_control_o  = 32'b00100000000000000000000000000000;
                    default: id_control_o = 32'b10000000000000000000000000000000;
                endcase
            end
            is_system: begin
                case (id_instruction_i[14:12])
                    3'b000: id_control_o  = 32'b00010000000000000000000000000000;
                    3'b001: id_control_o  = 32'b00001000000001000000000100001100;
                    3'b010: id_control_o  = 32'b00001000000010000000000100001100;
                    3'b011: id_control_o  = 32'b00001000000011000000000100001100;
                    3'b101: id_control_o  = 32'b00001000000001000000000100001100;
                    3'b110: id_control_o  = 32'b00001000000010000000000100001100;
                    3'b111: id_control_o  = 32'b00001000000011000000000100001100;
                    default: id_control_o = 32'b10000000000000000000000000000000;
                endcase
            end
            is_m:      begin
                id_control_o = 32'b01001000000000000000000000000000;
            end
            default:   begin
                id_control_o = 32'b10000000000000000000000000000000;
            end
        endcase
    end
    //--------------------------------------------------------------------------
endmodule
