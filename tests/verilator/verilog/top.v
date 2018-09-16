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
// Title       : CPU testbench
// Project     : Mirfak
// Description : Top module for the CPU testbench
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module top #(
             parameter [31:0] HART_ID         = 0,
             parameter [31:0] RESET_ADDR      = 32'h8000_0000,
             parameter [0:0]  ENABLE_COUNTERS = 1,
             parameter [0:0]  ENABLE_M_ISA    = 1,
             parameter        UCONTROL        = "ucontrol.list",
             parameter [31:0] MEM_SIZE        = 32'h0100_0000
             )(
               input wire clk_i,
               input wire rst_i,
               input wire xint_meip_i,
               input wire xint_mtip_i,
               input wire xint_msip_i
               );
    //--------------------------------------------------------------------------
    /*AUTOWIRE*/
    // Beginning of automatic wires (for undeclared instantiated-module outputs)
    wire [31:0]         dwbm_addr;            // From cpu of mirfak_core.v
    wire                dwbm_cyc;             // From cpu of mirfak_core.v
    wire [31:0]         dwbm_dat_o;           // From cpu of mirfak_core.v
    wire [31:0]         dwbm_dat_i;           // From cpu of mirfak_core.v
    wire [3:0]          dwbm_sel;             // From cpu of mirfak_core.v
    wire                dwbm_stb;             // From cpu of mirfak_core.v
    wire                dwbm_we;              // From cpu of mirfak_core.v
    wire [31:0]         iwbm_addr;            // From cpu of mirfak_core.v
    wire                iwbm_cyc;             // From cpu of mirfak_core.v
    wire [31:0]         iwbm_dat;             // From cpu of mirfak_core.v
    wire                iwbm_stb;             // From cpu of mirfak_core.v
    // End of automatics
    wire                iwbm_ack;
    wire                dwbm_ack;

    mirfak_core #(/*AUTOINSTPARAM*/
                  // Parameters
                  .HART_ID              (HART_ID[31:0]),
                  .RESET_ADDR           (RESET_ADDR[31:0]),
                  .ENABLE_COUNTERS      (ENABLE_COUNTERS[0:0]),
                  .ENABLE_M_ISA         (ENABLE_M_ISA[0:0]),
                  .UCONTROL             (UCONTROL)
                  ) cpu (/*AUTOINST*/
                         // Outputs
                         .iwbm_addr_o       (iwbm_addr),
                         .iwbm_cyc_o        (iwbm_cyc),
                         .iwbm_stb_o        (iwbm_stb),
                         .dwbm_addr_o       (dwbm_addr),
                         .dwbm_dat_o        (dwbm_dat_o),
                         .dwbm_sel_o        (dwbm_sel),
                         .dwbm_cyc_o        (dwbm_cyc),
                         .dwbm_stb_o        (dwbm_stb),
                         .dwbm_we_o         (dwbm_we),
                         // Inputs
                         .clk_i             (clk_i),
                         .rst_i             (rst_i),
                         .iwbm_dat_i        (iwbm_dat),
                         .iwbm_ack_i        (iwbm_ack),
                         .iwbm_err_i        (0),
                         .dwbm_dat_i        (dwbm_dat_i),
                         .dwbm_ack_i        (dwbm_ack),
                         .dwbm_err_i        (0),
                         .xint_meip_i       (xint_meip_i),
                         .xint_mtip_i       (xint_mtip_i),
                         .xint_msip_i       (xint_msip_i));
    //
    ram #(/*AUTOINSTPARAM*/
          // Parameters
          .ADDR_WIDTH($clog2(MEM_SIZE)), // 16 MB
          .BASE_ADDR(RESET_ADDR)
          ) memory (/*AUTOINST*/
                    // Outputs
                    .iwbs_dat_o      (iwbm_dat),
                    .iwbs_ack_o      (iwbm_ack),
                    .dwbs_dat_o      (dwbm_dat_i),
                    .dwbs_ack_o      (dwbm_ack),
                    // Inputs
                    .iwbs_addr_i     (iwbm_addr),
                    .iwbs_cyc_i      (iwbm_cyc),
                    .iwbs_stb_i      (iwbm_stb),
                    .dwbs_addr_i     (dwbm_addr),
                    .dwbs_dat_i      (dwbm_dat_o),
                    .dwbs_sel_i      (dwbm_sel),
                    .dwbs_cyc_i      (dwbm_cyc),
                    .dwbs_stb_i      (dwbm_stb),
                    .dwbs_we_i       (dwbm_we));
    //--------------------------------------------------------------------------
endmodule

// Local Variables:
// verilog-library-directories:("." "../../hardware")
// End:
