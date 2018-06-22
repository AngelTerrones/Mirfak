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

module mirfak_decoder #(
                        parameter [0:0]  ENABLE_MULTDIV = 1,
                        parameter UCONTROL = ""
                        )(// verilator lint_off UNUSED
                          input wire [31:0]     id_instruction_i,
                          // verilator lint_on UNUSED
                          output reg [`CTRL_SZ] id_control_o
                          );
    //--------------------------------------------------------------------------
    reg [`CTRL_SZ] ucontrol [0:127];
    reg [6:0]      is_instr;
    reg            is_lui, is_auipc, is_jal, is_jalr, is_branch, is_load;
    reg            is_store, is_ri, is_rr, is_fence, is_system, is_m;
    //
    initial begin
        $readmemb(UCONTROL, ucontrol);
    end
    //
    always @(*) begin
        is_lui     = id_instruction_i[6:0] == 7'b0110111;
        is_auipc   = id_instruction_i[6:0] == 7'b0010111;
        is_jal     = id_instruction_i[6:0] == 7'b1101111;
        is_jalr    = id_instruction_i[6:0] == 7'b1100111;
        is_branch  = id_instruction_i[6:0] == 7'b1100011;
        is_load    = id_instruction_i[6:0] == 7'b0000011;
        is_store   = id_instruction_i[6:0] == 7'b0100011;
        is_ri      = id_instruction_i[6:0] == 7'b0010011 && ((id_instruction_i[13:12] == 2'b01) ? (!id_instruction_i[31] && id_instruction_i[29:25] == 5'b00000) : 1);
        is_rr      = id_instruction_i[6:0] == 7'b0110011 && !id_instruction_i[31] && id_instruction_i[29:25] == 5'b00000;
        is_fence   = id_instruction_i[6:0] == 7'b0001111;
        is_system  = id_instruction_i[6:0] == 7'b1110011;
        is_m       = id_instruction_i[6:0] == 7'b0110011 && id_instruction_i[31:25] == 7'b0000001 && ENABLE_MULTDIV;
        // upper bits: instruction type
        // low bits:   funct3
        case (1'b1)
            is_lui:    is_instr[6:3]  = 0;  // lui
            is_auipc:  is_instr[6:3]  = 1;  // auipc
            is_jal:    is_instr[6:3]  = 2;  // jal
            is_jalr:   is_instr[6:3]  = 3;  // jalr
            is_branch: is_instr[6:3]  = 4;  // branch
            is_load:   is_instr[6:3]  = 5;  // load
            is_store:  is_instr[6:3]  = 6;  // store
            is_ri:     is_instr[6:3]  = 7;  // RI
            is_rr:     is_instr[6:3]  = 8;  // RR
            is_fence:  is_instr[6:3]  = 9;  // fence
            is_system: is_instr[6:3]  = 10; // system
            is_m:      is_instr[6:3]  = 11; // system
            default:   is_instr[6:3]  = 15; // invalid one
        endcase
        is_instr[2:0] = id_instruction_i[14:12];
        //
        id_control_o = ucontrol[is_instr];
    end
    //--------------------------------------------------------------------------
endmodule
