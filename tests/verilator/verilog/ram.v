// -----------------------------------------------------------------------------
// Copyright (C) 2019 Angel Terrones <angelterrones@gmail.com>
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
		// TODO: FIX THIS SHIT: we == 1 writes even if cyc is 0
		localparam BYTES = 2**ADDR_WIDTH;
		//
		byte                    mem[0:BYTES - 1]; // FFS, this MUST BE BYTE, FOR DPI.
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
		// SystemVerilog DPI functions
		export "DPI-C" function ram_v_dpi_read_word;
		export "DPI-C" function ram_v_dpi_read_byte;
		export "DPI-C" function ram_v_dpi_write_word;
		export "DPI-C" function ram_v_dpi_write_byte;
		export "DPI-C" function ram_v_dpi_load;
		import "DPI-C" function void ram_c_dpi_load(input byte mem[], input string filename);
		//
		function int ram_v_dpi_read_word(int address);
				if (address[31:ADDR_WIDTH] != BASE_ADDR[31:ADDR_WIDTH]) begin
						$display("[RAM read word] Bad address: %h. Abort.\n", address);
						$finish;
				end
				return {mem[address[ADDR_WIDTH-1:0] + 3],
								mem[address[ADDR_WIDTH-1:0] + 2],
								mem[address[ADDR_WIDTH-1:0] + 1],
								mem[address[ADDR_WIDTH-1:0] + 0]};
		endfunction
		//
		function byte ram_v_dpi_read_byte(int address);
				if (address[31:ADDR_WIDTH] != BASE_ADDR[31:ADDR_WIDTH]) begin
						$display("[RAM read byte] Bad address: %h. Abort.\n", address);
						$finish;
				end
				return mem[address[ADDR_WIDTH-1:0]];
		endfunction
		//
		function void ram_v_dpi_write_word(int address, int data);
				if (address[31:ADDR_WIDTH] != BASE_ADDR[31:ADDR_WIDTH]) begin
						$display("[RAM write word] Bad address: %h. Abort.\n", address);
						$finish;
				end
				mem[address[ADDR_WIDTH-1:0] + 0] = data[7:0];
				mem[address[ADDR_WIDTH-1:0] + 1] = data[15:8];
				mem[address[ADDR_WIDTH-1:0] + 2] = data[23:16];
				mem[address[ADDR_WIDTH-1:0] + 3] = data[31:24];
		endfunction
		//
		function void ram_v_dpi_write_byte(int address, byte data);
				if (address[31:ADDR_WIDTH] != BASE_ADDR[31:ADDR_WIDTH]) begin
						$display("[RAM write word] Bad address: %h. Abort.\n", address);
						$finish;
				end
				mem[address[ADDR_WIDTH-1:0]] = data;
		endfunction
		//
		function void ram_v_dpi_load(string filename);
				ram_c_dpi_load(mem, filename);
		endfunction
		//--------------------------------------------------------------------------
endmodule
