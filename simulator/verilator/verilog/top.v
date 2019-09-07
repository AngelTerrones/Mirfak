// -----------------------------------------------------------------------------
// Copyright (C) 2019 Angel Terrones <angelterrones@gmail.com>
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
             parameter [31:0] MEM_SIZE        = 32'h0100_0000
             )(
               input wire clk_i,
               input wire rst_i,
               input wire xint_meip_i,
               input wire xint_mtip_i,
               input wire xint_msip_i
               );
    //--------------------------------------------------------------------------
    localparam ADDR_WIDTH = $clog2(MEM_SIZE);
    localparam BASE_ADDR  = RESET_ADDR;
    /*AUTOWIRE*/
    // Beginning of automatic wires (for undeclared instantiated-module outputs)
    wire                dwbm_ack_i;             // From memory of ram.v
    wire [31:0]         dwbm_addr_o;            // From cpu of mirfak_core.v
    wire                dwbm_cyc_o;             // From cpu of mirfak_core.v
    wire [31:0]         dwbm_dat_i;             // From memory of ram.v
    wire [31:0]         dwbm_dat_o;             // From cpu of mirfak_core.v
    wire [3:0]          dwbm_sel_o;             // From cpu of mirfak_core.v
    wire                dwbm_stb_o;             // From cpu of mirfak_core.v
    wire                dwbm_we_o;              // From cpu of mirfak_core.v
    wire                iwbm_ack_i;             // From memory of ram.v
    wire [31:0]         iwbm_addr_o;            // From cpu of mirfak_core.v
    wire                iwbm_cyc_o;             // From cpu of mirfak_core.v
    wire [31:0]         iwbm_dat_i;             // From memory of ram.v
    wire                iwbm_stb_o;             // From cpu of mirfak_core.v
    // End of automatics

    /*
     mirfak_core AUTO_TEMPLATE (
     .iwbm_err_i (0),
     .dwbm_err_i(0),
     );
     */
    mirfak_core #(/*AUTOINSTPARAM*/
                  // Parameters
                  .HART_ID              (HART_ID[31:0]),
                  .RESET_ADDR           (RESET_ADDR[31:0]),
                  .ENABLE_COUNTERS      (ENABLE_COUNTERS[0:0]),
                  .ENABLE_M_ISA         (ENABLE_M_ISA[0:0])
                  ) cpu (/*AUTOINST*/
                         // Outputs
                         .iwbm_addr_o           (iwbm_addr_o[31:0]),
                         .iwbm_cyc_o            (iwbm_cyc_o),
                         .iwbm_stb_o            (iwbm_stb_o),
                         .dwbm_addr_o           (dwbm_addr_o[31:0]),
                         .dwbm_dat_o            (dwbm_dat_o[31:0]),
                         .dwbm_sel_o            (dwbm_sel_o[3:0]),
                         .dwbm_cyc_o            (dwbm_cyc_o),
                         .dwbm_stb_o            (dwbm_stb_o),
                         .dwbm_we_o             (dwbm_we_o),
                         // Inputs
                         .clk_i                 (clk_i),
                         .rst_i                 (rst_i),
                         .iwbm_dat_i            (iwbm_dat_i[31:0]),
                         .iwbm_ack_i            (iwbm_ack_i),
                         .iwbm_err_i            (0),             // Templated
                         .dwbm_dat_i            (dwbm_dat_i[31:0]),
                         .dwbm_ack_i            (dwbm_ack_i),
                         .dwbm_err_i            (0),             // Templated
                         .xint_meip_i           (xint_meip_i),
                         .xint_mtip_i           (xint_mtip_i),
                         .xint_msip_i           (xint_msip_i));

    /*
     ram AUTO_TEMPLATE (
     .iwbs_\(.*\)_i (iwbm_\1_o[]),
     .dwbs_\(.*\)_i (dwbm_\1_o[]),
     .iwbs_\(.*\)_o (iwbm_\1_i[]),
     .dwbs_\(.*\)_o (dwbm_\1_i[]),
     );
    */
    ram #(/*AUTOINSTPARAM*/
          // Parameters
          .ADDR_WIDTH (ADDR_WIDTH),
          .BASE_ADDR  (BASE_ADDR)
          ) memory (/*AUTOINST*/
                    // Outputs
                    .iwbs_dat_o        (iwbm_dat_i[31:0]),  // Templated
                    .iwbs_ack_o        (iwbm_ack_i),        // Templated
                    .dwbs_dat_o        (dwbm_dat_i[31:0]),  // Templated
                    .dwbs_ack_o        (dwbm_ack_i),        // Templated
                                                            // Inputs
                    .iwbs_addr_i       (iwbm_addr_o[31:0]), // Templated
                    .iwbs_cyc_i        (iwbm_cyc_o),        // Templated
                    .iwbs_stb_i        (iwbm_stb_o),        // Templated
                    .dwbs_addr_i       (dwbm_addr_o[31:0]), // Templated
                    .dwbs_dat_i        (dwbm_dat_o[31:0]),  // Templated
                    .dwbs_sel_i        (dwbm_sel_o[3:0]),   // Templated
                    .dwbs_cyc_i        (dwbm_cyc_o),        // Templated
                    .dwbs_stb_i        (dwbm_stb_o),        // Templated
                    .dwbs_we_i         (dwbm_we_o));        // Templated
    //--------------------------------------------------------------------------
endmodule

// Local Variables:
// verilog-library-directories: ("." "../../../rtl")
// flycheck-verilator-include-path: ("." "../../../rtl")
// End:
