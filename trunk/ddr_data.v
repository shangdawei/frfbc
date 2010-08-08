/*
** -----------------------------------------------------------------------------**
** ddr_data.v
**
** Copyright (C) 2010 WeiYue
**
** -----------------------------------------------------------------------------**
**  This file is part of FRFBC (FPGA Remote Framebuffer Controller)
**  FRFBC is free software - hardware description language (HDL) code.
** 
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
** -----------------------------------------------------------------------------**
**
*/

`timescale 1ns / 1ps

module ddr_data(
                clk,
                clk_dqs,
                reset_n,
                sys_dataout,
					 sys_dataout_en,
                sys_datain,
					 sys_datain_en,
                cstate,
                wren,
                dqin,
                dqout,
                dqout_en,
                dqsout,
                dqsout_en,
                dqm_out,
                readrdy
                );

`include "ddr_par.v"

//---- INPUTS
input                    clk;             // Clkx from HPPLL
input                    clk_dqs;           
input 			          reset_n;         // System reset
input [3:0] 		       cstate;          // Control state machine output
input 			          wren;            // Write enable signal 
input [DSIZE-1:0] 	         sys_datain;      // System data in
input [DSIZE/2-1:0] 	    dqin;            // DDR data in (read data)
input                    readrdy;

//---- OUTPUTS
output               	 dqout_en;        // DDR output enables
output [DSIZE/2-1:0] 	 dqout;           // DDR output (write data)
output [DSIZE/16-1:0] 	 dqsout;          // DDR output strobe
output						 sys_dataout_en;
output [DSIZE-1:0] 	    sys_dataout;
output						 sys_datain_en;
output [DSIZE/16-1:0] 	 dqm_out;         // Data mask output to DDR
output                   dqsout_en;
wire                	    dqout_en;
wire  [DSIZE/2-1:0] 	    dqout; 
wire 	    					 dqsout_en; 
wire  [DSIZE/16-1:0]      dqsout;
wire [DSIZE-1:0] 	       dqin_reg;
reg  [DSIZE-1:0]         sys_datain_reg;
reg                      sys_datain_en;
reg 			             sys_rdyn;
reg  [DSIZE-1:0] 	          sys_dataout;
reg  [DSIZE-1:0] 	          sys_dataout_reg;

reg 							 sys_dataout_en;
reg 			             write_rdy_d1;
reg 			             write_rdy_d2;
reg 			             write_rdy_d3;
reg 			             write_rdy_d4;
reg 			             write_rdy;
reg							 read_rdy;
reg							 read_rdy_2;
reg                      dqsout_en_d0;
reg                      dqsout_en_d1;
//--- WIRES
wire                     dqs_1;


assign dqm_out = {DSIZE/16{1'b0}};
//====================================================================
//  Read Cycle Data Path
//====================================================================

always @(negedge clk or negedge reset_n) begin
	if (reset_n == 1'b0) begin
      sys_dataout_reg <= 32'b0;
   end else begin
		sys_dataout_reg <= dqin_reg;
   end
end

always @(posedge clk or negedge reset_n) begin
   if(~reset_n) begin
      sys_dataout <= 32'b0;
   end else begin
      sys_dataout <= sys_dataout_reg;
   end
end


IDDR2 IDDR_0(.D(dqin[0]),.C1(clk),.C0(~clk),.Q0(dqin_reg[0]),.Q1(dqin_reg[16]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_1(.D(dqin[1]),.C1(clk),.C0(~clk),.Q0(dqin_reg[1]),.Q1(dqin_reg[17]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_2(.D(dqin[2]),.C1(clk),.C0(~clk),.Q0(dqin_reg[2]),.Q1(dqin_reg[18]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_3(.D(dqin[3]),.C1(clk),.C0(~clk),.Q0(dqin_reg[3]),.Q1(dqin_reg[19]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_4(.D(dqin[4]),.C1(clk),.C0(~clk),.Q0(dqin_reg[4]),.Q1(dqin_reg[20]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_5(.D(dqin[5]),.C1(clk),.C0(~clk),.Q0(dqin_reg[5]),.Q1(dqin_reg[21]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_6(.D(dqin[6]),.C1(clk),.C0(~clk),.Q0(dqin_reg[6]),.Q1(dqin_reg[22]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_7(.D(dqin[7]),.C1(clk),.C0(~clk),.Q0(dqin_reg[7]),.Q1(dqin_reg[23]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_8(.D(dqin[8]),.C1(clk),.C0(~clk),.Q0(dqin_reg[8]),.Q1(dqin_reg[24]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_9(.D(dqin[9]),.C1(clk),.C0(~clk),.Q0(dqin_reg[9]),.Q1(dqin_reg[25]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_10(.D(dqin[10]),.C1(clk),.C0(~clk),.Q0(dqin_reg[10]),.Q1(dqin_reg[26]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_11(.D(dqin[11]),.C1(clk),.C0(~clk),.Q0(dqin_reg[11]),.Q1(dqin_reg[27]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_12(.D(dqin[12]),.C1(clk),.C0(~clk),.Q0(dqin_reg[12]),.Q1(dqin_reg[28]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_13(.D(dqin[13]),.C1(clk),.C0(~clk),.Q0(dqin_reg[13]),.Q1(dqin_reg[29]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_14(.D(dqin[14]),.C1(clk),.C0(~clk),.Q0(dqin_reg[14]),.Q1(dqin_reg[30]),.CE(1'b1),.S(1'b0),.R(1'b0));
IDDR2 IDDR_15(.D(dqin[15]),.C1(clk),.C0(~clk),.Q0(dqin_reg[15]),.Q1(dqin_reg[31]),.CE(1'b1),.S(1'b0),.R(1'b0));

//====================================================================
//  Write Cycle Data Path
//====================================================================

wire [1:0] dqsout_reg;
reg  dqsout_en_reg;

assign dqsout_en = dqsout_en_d0|dqsout_en_d1;
assign dqout_en = dqsout_en;
assign dqsout = (write_rdy|write_rdy_d1|write_rdy_d2|write_rdy_d3|dqsout_en_d1)?dqsout_reg:2'bz;
FDCPE fd_dqs_0(.D(~dqsout_reg[0]),.Q(dqsout_reg[0]),.C(clk_dqs),.CLR(~dqsout_en_reg),.PRE(1'b0),.CE(1'b1));
FDCPE fd_dqs_1(.D(~dqsout_reg[1]),.Q(dqsout_reg[1]),.C(clk_dqs),.CLR(~dqsout_en_reg),.PRE(1'b0),.CE(1'b1));
always @ (posedge clk_dqs or negedge reset_n) begin
   if(~reset_n)
      dqsout_en_reg <= 1'b0;
   else
      dqsout_en_reg <= dqsout_en_d0?1'b1:1'b0;
end


always @(posedge clk or negedge reset_n) begin
   if(reset_n == 1'b0) begin
      sys_datain_reg <= 32'b0;
   end else begin
      sys_datain_reg <= sys_datain;
   end
end

ODDR2 ODDR_0(.D1(sys_datain[0]),.D0(sys_datain[16]),.C1(clk),.C0(~clk),.Q(dqout[0]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_1(.D1(sys_datain[1]),.D0(sys_datain[17]),.C1(clk),.C0(~clk),.Q(dqout[1]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_2(.D1(sys_datain[2]),.D0(sys_datain[18]),.C1(clk),.C0(~clk),.Q(dqout[2]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_3(.D1(sys_datain[3]),.D0(sys_datain[19]),.C1(clk),.C0(~clk),.Q(dqout[3]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_4(.D1(sys_datain[4]),.D0(sys_datain[20]),.C1(clk),.C0(~clk),.Q(dqout[4]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_5(.D1(sys_datain[5]),.D0(sys_datain[21]),.C1(clk),.C0(~clk),.Q(dqout[5]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_6(.D1(sys_datain[6]),.D0(sys_datain[22]),.C1(clk),.C0(~clk),.Q(dqout[6]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_7(.D1(sys_datain[7]),.D0(sys_datain[23]),.C1(clk),.C0(~clk),.Q(dqout[7]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_8(.D1(sys_datain[8]),.D0(sys_datain[24]),.C1(clk),.C0(~clk),.Q(dqout[8]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_9(.D1(sys_datain[9]),.D0(sys_datain[25]),.C1(clk),.C0(~clk),.Q(dqout[9]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_10(.D1(sys_datain[10]),.D0(sys_datain[26]),.C1(clk),.C0(~clk),.Q(dqout[10]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_11(.D1(sys_datain[11]),.D0(sys_datain[27]),.C1(clk),.C0(~clk),.Q(dqout[11]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_12(.D1(sys_datain[12]),.D0(sys_datain[28]),.C1(clk),.C0(~clk),.Q(dqout[12]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_13(.D1(sys_datain[13]),.D0(sys_datain[29]),.C1(clk),.C0(~clk),.Q(dqout[13]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_14(.D1(sys_datain[14]),.D0(sys_datain[30]),.C1(clk),.C0(~clk),.Q(dqout[14]),.CE(1'b1),.S(1'b0),.R(1'b0));
ODDR2 ODDR_15(.D1(sys_datain[15]),.D0(sys_datain[31]),.C1(clk),.C0(~clk),.Q(dqout[15]),.CE(1'b1),.S(1'b0),.R(1'b0));

//====================================================================
// Generation of sys_rdyn. When sys_rdyn goes low
// data transfer takes place. Applies to read and write
//====================================================================

always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      sys_rdyn        <= 1'b1;
      write_rdy_d1    <= 1'b0;
      write_rdy_d2    <= 1'b0;
      write_rdy_d3    <= 1'b0;
      write_rdy_d4    <= 1'b0;
      sys_dataout_en  <= 1'b0;
      sys_datain_en   <= 1'b0;
      dqsout_en_d0    <= 1'b0;
      dqsout_en_d1    <= 1'b0;
      read_rdy        <= 1'b0;
   end else begin
      
      // Generate for read and write cycles, during data transfer
      // This will be useful to directly attach to processors
      // Also during refresh time, if master requests read/write cycles.
      write_rdy_d1       <= write_rdy;
      write_rdy_d2       <= write_rdy_d1;
      write_rdy_d3       <= write_rdy_d2;
      write_rdy_d4       <= write_rdy_d3;
      read_rdy           <= readrdy;
		read_rdy_2		    <= read_rdy;
      sys_dataout_en     <= read_rdy;
      sys_datain_en      <= write_rdy|write_rdy_d1|write_rdy_d2|write_rdy_d3;
      dqsout_en_d0       <= sys_datain_en;
      dqsout_en_d1       <= dqsout_en_d0;
	end
end



// Generation of write_rdy (combinational signal)

always @ (cstate ) begin
        write_rdy <= 1'b0;
   case (cstate)
     c_WRITEA: begin
        write_rdy <= 1'b1;
     end
     default: begin
        write_rdy <= 1'b0;
     end
   endcase
end


endmodule

