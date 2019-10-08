// -----------------------------------------------------------------------------
// Copyright (C) 2019 Angel Terrones <angelterrones@gmail.com>
// -----------------------------------------------------------------------------

`default_nettype none
`timescale 1 ns / 1 ps

module mirfak_multiplier (
                          input wire clk_i,
                          input wire rst_i,
                          // pipeline interface
                          input wire [31:0] mult_op1,
                          input wire [31:0] mult_op2,
                          input wire [1:0]  mult_cmd,
                          input wire        mult_enable,
                          input wire        mult_abort,
                          output reg [31:0] mult_result,
                          output reg        mult_ack
                          );
    //--------------------------------------------------------------------------
    wire       is_any_mulh;
    wire       is_op1_signed, is_op2_signed;
    reg [32:0] op1_q, op2_q;
    reg [63:0] result;
    reg [1:0]  active;
    //
    assign is_any_mulh   = |mult_cmd;
    assign is_op1_signed = mult_cmd[1] ^ mult_cmd[0];
    assign is_op2_signed = mult_cmd == 2'b01;
    //
    always @(posedge clk_i) begin
        // verilator lint_off WIDTH
        if (is_op1_signed) begin
            op1_q <= $signed(mult_op1);
        end else begin
            op1_q <= $unsigned(mult_op1);
        end
        //
        if (is_op2_signed) begin
            op2_q <= $signed(mult_op2);
        end else begin
            op2_q <= $unsigned(mult_op2);
        end
        // verilator lint_on WIDTH
        result      <= $signed(op1_q) * $signed(op2_q);
        mult_result <= (is_any_mulh) ? result[63:32] : result[31:0];
    end
    //
    always @(posedge clk_i) begin
        if (rst_i || mult_ack || mult_abort) begin
            active   <= 0;
            mult_ack <= 0;
        end else begin
            active   <= {active[0], mult_enable};
            mult_ack <= active[1];
        end
    end
    //--------------------------------------------------------------------------
endmodule
