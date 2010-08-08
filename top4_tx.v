/*
** -----------------------------------------------------------------------------**
** top4_tx.v
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

`timescale 1 ps / 1ps

module top4_tx(
input					clkin, 				// clock in
input    			clkx3p5,
input		[47:0]	lcd_data,
input    			lcd_de,
input    			lcd_vsync,
input    			lcd_hsync,
input					rstin_n,				// reset (active low)
output	[3:0]		dataouta_p, dataouta_n,		// lvds data outputs
output   [3:0]   	dataoutb_p, dataoutb_n,
output				clkouta1_p,  clkouta1_n,
output      		clkoutb1_p,  clkoutb1_n
);	


wire 	[7:0]		outdata ;			// output data lines
wire  [7:0] 	outdatb ;
wire 				clkoutint ;	          	// forwarded output clock
wire     		clkoutint_2;
wire 	[1:0]		oclkinta ;	          	// 
wire 	[1:0]		oclkintb ;	          	// 
wire 				clkoutaint ;	          	// forwarded output clock from macro 3:4 or 4:3 duty cycle
wire 				clkoutbint ;	          	// forwarded output clock using DCM clk0 - 50% output duty cycle 
reg 	[27:0]	txdata ;			// data for transmission
reg   [27:0]	txdatb ;
wire 	[7:0]		tx_output_fix ;
wire 	[3:0]		tx_output_reg ;
wire 	[7:0]		tx_output_fix_b ;
wire 	[3:0]		tx_output_reg_b ;

reg sxga_vsync,sxga_hsync;
reg sxga_de_o;

wire [7:0] ra;
wire [7:0] ga;
wire [7:0] ba;
wire [7:0] rb;
wire [7:0] gb;
wire [7:0] bb;

wire [27:0]   datain = {ra[6],ba[2],ga[1],ra[0],ra[7],ba[3],ga[2],ra[1],ga[6],ba[4],ga[3],ra[2],ga[7],ba[5],ga[4],ra[3],ba[6],sxga_hsync,ga[5],ra[4],ba[7],sxga_vsync,ba[0],ra[5],1'b0,sxga_de_o,ba[1],ga[0]};
wire [27:0]   datbin = {rb[6],bb[2],gb[1],rb[0],rb[7],bb[3],gb[2],rb[1],gb[6],bb[4],gb[3],rb[2],gb[7],bb[5],gb[4],rb[3],bb[6],1'b0,gb[5],rb[4],bb[7],1'b0,bb[0],rb[5],1'b0,1'b0,bb[1],gb[0]};

assign ra = lcd_data[47:40];
assign ga = lcd_data[39:32];
assign ba = lcd_data[31:24];
assign rb = lcd_data[23:16];
assign gb = lcd_data[15:8];
assign bb = lcd_data[7:0];


parameter [3:0] TX_SWAP_MASK = 4'b0000 ;	// pinswap mask for 4 output bits (0 = no swap (default), 1 = swap)

genvar i ;
generate
for (i = 0 ; i <= 3 ; i = i + 1)
begin : loop0
OBUFDS	obuf_d   (.I(tx_output_reg[i]), .O(dataouta_p[i]), .OB(dataouta_n[i]));
OBUFDS	obuf_d_2   (.I(tx_output_reg_b[i]), .O(dataoutb_p[i]), .OB(dataoutb_n[i]));
ODDR2 	#(.DDR_ALIGNMENT("NONE")) fd_ioc	(.C0(clkx3p5), .C1(~clkx3p5), .D0(tx_output_fix[i+4]), .D1(tx_output_fix[i]), .CE(1'b1), .R(1'b0), .S(1'b0), .Q(tx_output_reg[i])) ;
ODDR2 	#(.DDR_ALIGNMENT("NONE")) fd_ioc_2	(.C0(clkx3p5), .C1(~clkx3p5), .D0(tx_output_fix_b[i+4]), .D1(tx_output_fix_b[i]), .CE(1'b1), .R(1'b0), .S(1'b0), .Q(tx_output_reg_b[i])) ;
assign tx_output_fix[i]   = outdata[i]   ^ TX_SWAP_MASK[i] ;
assign tx_output_fix[i+4] = outdata[i+4] ^ TX_SWAP_MASK[i] ;
assign tx_output_fix_b[i]   = outdatb[i]   ^ TX_SWAP_MASK[i] ;
assign tx_output_fix_b[i+4] = outdatb[i+4] ^ TX_SWAP_MASK[i] ;

end
endgenerate

ODDR2 	#(.DDR_ALIGNMENT("NONE")) ca_ddr_reg   (.C0(clkx3p5), .C1(~clkx3p5), .D0(oclkinta[1]), .D1(oclkinta[0]), .CE(1'b1), .R(1'b0), .S(1'b0), .Q(clkoutaint)) ;
ODDR2 	#(.DDR_ALIGNMENT("NONE")) ca_ddr_reg_2   (.C0(clkx3p5), .C1(~clkx3p5), .D0(oclkintb[1]), .D1(oclkintb[0]), .CE(1'b1), .R(1'b0), .S(1'b0), .Q(clkoutbint)) ;

assign clkoutint = clkoutaint	;	// use this line for 3:4 or 4:3 macro generated forwarded clock
assign clkoutint_2 = clkoutbint;

OBUFDS	lvds_clka_obuf	(.I(clkoutint),   .O(clkouta1_p),    .OB(clkouta1_n) );
OBUFDS	lvds_clka_obuf_2	(.I(clkoutint_2),   .O(clkoutb1_p),    .OB(clkoutb1_n) );

serdes_4b_7to1_wrapper tx0(
	.clk		(clkin),
	.datain 	(txdata),
	.rst   		(~rstin_n),
	.clkx3p5   	(clkx3p5),
	.dataout	(outdata),
	.clkout		(oclkinta));	// clock output

serdes_4b_7to1_wrapper tx1(
	.clk		(clkin),
	.datain 	(txdatb),
	.rst   		(~rstin_n),
	.clkx3p5   	(clkx3p5),
	.dataout	(outdatb),
	.clkout		(oclkintb));	// clock output

always @ (posedge clkin or negedge rstin_n)
begin
if (~rstin_n) begin
	txdata <= 28'b0000000000000000000000000000 ;
   txdatb <= 28'b0000000000000000000000000000 ;
end
else begin
	txdata <= datain ;
   txdatb <= datbin ;
end
end

always @ (posedge clkin or negedge rstin_n)
begin
if (~rstin_n) begin
	sxga_de_o = 0;
	sxga_vsync = 0;
	sxga_hsync = 0;
end
else begin
	sxga_de_o = lcd_de;
	sxga_vsync = lcd_vsync;
	sxga_hsync = lcd_hsync;
end
end



         

endmodule


