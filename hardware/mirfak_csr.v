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
// Title       : Control Status Registers
// Project     : Mirfak
// Description : CPU control registers
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_csr #(
                    parameter [31:0] HART_ID = 0,
                    parameter [0:0]  ENABLE_COUNTERS = 1,
                    parameter [0:0]  ENABLE_M_ISA = 0
                    )(
                      input wire         clk_i,
                      input wire         rst_i,
                      // cpu interface
                      input wire         xint_meip_i,
                      input wire         xint_mtip_i,
                      input wire         xint_msip_i,
                      // pipeline interface
                      input wire [11:0]  csr_addr_i,
                      input wire [1:0]   csr_cmd_i,
                      input wire         csr_rs1_zero_i,
                      input wire [31:0]  csr_wdata_i,
                      output wire [31:0] csr_rdata_o,
                      // exception signals
                      input wire         wb_exception_i,
                      input wire         wb_xret_i,
                      // verilator lint_off UNUSED
                      input wire [31:0]  wb_exception_pc_i,
                      // verilator lint_on UNUSED
                      input wire [3:0]   wb_xcause_i,
                      input wire [31:0]  wb_mtval_i,
                      output wire        csr_exception_o,
                      output reg         xinterrupt_o,
                      output reg [3:0]   xint_xcause_o,
                      output wire [31:0] pc_except_o,
                      output wire [31:0] pc_xret_o,
                      // extra
                      input wire         wb_bubble_i
                      );
    //--------------------------------------------------------------------------
    wire [31:0] mstatus;
    wire [31:0] mie;
    reg [31:0]  mtvec;
    reg [31:0]  mscratch;
    reg [31:0]  mepc;
    wire [31:0] mcause;
    wire [31:0] mip;
    reg [31:0]  mtval;
    reg [63:0]  cycle;
    reg [63:0]  instret;
    // msatus fields
    reg         mstatus_mpie;
    reg         mstatus_mie;
    // mie fields
    reg         mie_meie, mie_mtie, mie_msie;
    // mcause
    reg         mcause_interrupt;
    reg [3:0]   mcause_mecode;
    // interrupts
    // verilator lint_off UNUSED
    wire [31:0] pend_int;
    // verilator lint_on UNUSED
    // extra signals
    reg [16:0]  is_csr_reg;
    wire        csr_illegal, csr_wen;
    reg [31:0]  csr_wdata, csr_rdata;
    wire        valid_cmd;
    //
    assign mstatus     = {19'b0, 2'b11, 3'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};
    assign mip         = {20'b0, xint_meip_i, 3'b0, xint_mtip_i, 3'b0, xint_msip_i, 3'b0};
    assign mie         = {20'b0, mie_meie, 3'b0, mie_mtie, 3'b0, mie_msie, 3'b0};
    assign mcause      = {mcause_interrupt, 27'b0, mcause_mecode};
    assign valid_cmd   = (csr_cmd_i[1] && !csr_rs1_zero_i) || (csr_cmd_i == CSR_CMD_WRITE);
    assign csr_illegal = (valid_cmd && (csr_addr_i[11:10] == 2'b11)) || (|csr_cmd_i && !(|is_csr_reg));
    assign csr_wen     = |csr_cmd_i && (csr_addr_i[11:10] != 2'b11) && |is_csr_reg;  // write only if cmd, is r/w, and the register exists.
    // check CSR address
    always @(*) begin
        is_csr_reg[0]   = csr_addr_i == MISA;
        is_csr_reg[1]   = csr_addr_i == MHARTID;
        is_csr_reg[2]   = csr_addr_i == MVENDORID;
        is_csr_reg[3]   = csr_addr_i == MARCHID;
        is_csr_reg[4]   = csr_addr_i == MIMPID;
        is_csr_reg[5]   = csr_addr_i == MSTATUS;
        is_csr_reg[6]   = csr_addr_i == MIE;
        is_csr_reg[7]   = csr_addr_i == MTVEC;
        is_csr_reg[8]   = csr_addr_i == MSCRATCH;
        is_csr_reg[9]   = csr_addr_i == MEPC;
        is_csr_reg[10]  = csr_addr_i == MCAUSE;
        is_csr_reg[11]  = csr_addr_i == MTVAL;
        is_csr_reg[12]  = csr_addr_i == MIP;
        is_csr_reg[13]  = csr_addr_i == CYCLE    || csr_addr_i == MCYCLE;
        is_csr_reg[14]  = csr_addr_i == INSTRET  || csr_addr_i == MINSTRET;
        is_csr_reg[15]  = csr_addr_i == CYCLEH   || csr_addr_i == MCYCLEH;
        is_csr_reg[16]  = csr_addr_i == INSTRETH || csr_addr_i == MINSTRETH;
    end
    // interrupts
    assign pend_int  = mstatus_mie ? mip & mie : 0;
    always @(posedge clk_i) begin
        xinterrupt_o <= |{pend_int[11], pend_int[7], pend_int[3]} && ! wb_exception_i;
        case (1'b1)
            pend_int[7]:  xint_xcause_o <= I_M_TIMER;
            pend_int[3]:  xint_xcause_o <= I_M_SOFTWARE;
            pend_int[11]: xint_xcause_o <= I_M_EXTERNAL;
        endcase
    end
    // write data aux
    always @(*) begin
        case (csr_cmd_i)
            CSR_CMD_WRITE: csr_wdata = csr_wdata_i;
            CSR_CMD_SET:   csr_wdata = csr_rdata | csr_wdata_i;
            CSR_CMD_CLEAR: csr_wdata = csr_rdata & ~csr_wdata_i;
            default:       csr_wdata = 32'hx;
        endcase
    end
    // wire
    // cycle register
    always @(posedge clk_i) begin
        if (ENABLE_COUNTERS) begin
            if (rst_i) begin
                cycle <= 0;
            end else begin
                case (1'b1)
                    csr_wen && is_csr_reg[13]: cycle[31:0]  <= csr_wdata;
                    csr_wen && is_csr_reg[15]: cycle[63:32] <= csr_wdata;
                    default:                   cycle        <= cycle + 1;
                endcase
            end
        end else begin
            cycle <= 64'bx;;
        end
    end
    // instret register
    always @(posedge clk_i) begin
        if (ENABLE_COUNTERS) begin
            if (rst_i) begin
                instret <= 0;
            end else begin
                case (1'b1)
                    csr_wen && is_csr_reg[14]: instret[31:0]  <= csr_wdata;
                    csr_wen && is_csr_reg[16]: instret[63:32] <= csr_wdata;
                    // verilator lint_off WIDTH
                    default:                   instret <= instret + !wb_bubble_i;
                    // verilator lint_on WIDTH
                endcase // case (1'b1)
            end
        end else begin
            instret <= 64'bx;;
        end
    end
    // mstatus register
    always @(posedge clk_i) begin
        if (rst_i) begin
            mstatus_mpie <= 0;
            mstatus_mie  <= 0;
        end else if (wb_exception_i) begin
            mstatus_mpie <= mstatus_mie;
            mstatus_mie  <= 0;
        end else if (wb_xret_i) begin
            mstatus_mpie <= 1;
            mstatus_mie  <= mstatus_mpie;
        end else if (csr_wen && is_csr_reg[5]) begin
            mstatus_mpie <= csr_wdata[7];
            mstatus_mie  <= csr_wdata[3];
        end
    end
    // mepc
    always @(posedge clk_i) begin
        if (rst_i) mepc <= 0;
        else if (wb_exception_i) mepc <= {wb_exception_pc_i[31:2], 2'b0};
        else if (csr_wen && is_csr_reg[9]) mepc <= {csr_wdata[31:2], 2'b0};
    end
    // mcause
    always @(posedge clk_i) begin
        if (rst_i) begin
            mcause_interrupt <= 0;
            mcause_mecode    <= 0;
        end else if (wb_exception_i) begin
            mcause_interrupt <= xinterrupt_o;
            mcause_mecode    <= wb_xcause_i;
        end else if (csr_wen && is_csr_reg[10]) begin
            mcause_interrupt <= csr_wdata[31];
            mcause_mecode    <= csr_wdata[3:0];
        end
    end
    // mtval
    always @(posedge clk_i) begin
        if (wb_exception_i) mtval <= wb_mtval_i;
        else if (csr_wen && is_csr_reg[11]) mtval <= csr_wdata;
    end
    // mie
    always @(posedge clk_i) begin
        if (rst_i) begin
            mie_meie <= 0;
            mie_mtie <= 0;
            mie_msie <= 0;
        end else if (csr_wen && is_csr_reg[6]) begin
            mie_meie <= csr_wdata[11];
            mie_mtie <= csr_wdata[7];
            mie_msie <= csr_wdata[3];
        end
    end
    // default
    always @(posedge clk_i) begin
        if (csr_wen) begin
            case (1'b1)
                is_csr_reg[7]: mtvec    <= csr_wdata;
                is_csr_reg[8]: mscratch <= csr_wdata;
            endcase
        end
    end
    // read registers
    wire [31:0] misa = {2'b01, 4'b0, (ENABLE_M_ISA) ? 26'h1100 : 26'h100};
    always @(*) begin
        case (1'b1)
            is_csr_reg[0]:                                  csr_rdata = misa;
            is_csr_reg[1]:                                  csr_rdata = HART_ID;
            |{is_csr_reg[2], is_csr_reg[3], is_csr_reg[4]}: csr_rdata = 0;
            is_csr_reg[5]:                                  csr_rdata = mstatus;
            is_csr_reg[6]:                                  csr_rdata = mie;
            is_csr_reg[7]:                                  csr_rdata = mtvec;
            is_csr_reg[8]:                                  csr_rdata = mscratch;
            is_csr_reg[9]:                                  csr_rdata = mepc;
            is_csr_reg[10]:                                 csr_rdata = mcause;
            is_csr_reg[11]:                                 csr_rdata = mtval;
            is_csr_reg[12]:                                 csr_rdata = mip;
            |{is_csr_reg[13], is_csr_reg[15]}:              csr_rdata = is_csr_reg[13] ? cycle[31:0]   : cycle[63:32];
            |{is_csr_reg[14], is_csr_reg[16]}:              csr_rdata = is_csr_reg[14] ? instret[31:0] : instret[63:32];
            default:                                        csr_rdata = 32'bx;
        endcase
    end
    //
    assign csr_exception_o = csr_illegal;
    assign pc_except_o     = mtvec;
    assign pc_xret_o       = mepc;
    assign csr_rdata_o     = csr_rdata;
    //--------------------------------------------------------------------------
endmodule
