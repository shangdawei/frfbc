`timescale 1ns / 1ps
/*
** -----------------------------------------------------------------------------**
** test_top.v
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
module test_top(
clk,
clk_2,
rst_n

    );
input clk;
input clk_2;
input rst_n;	 
	 
wire ddr_ckp;
wire ddr_ckn;
wire ddr_cke;
wire ddr_wen;
wire ddr_casn;
wire ddr_rasn;
wire [1:0] ddr_ba;
wire [11:0] ddr_add;
wire [1:0] ddr_dm;
wire [15:0] ddr_dq;
wire [1:0]  ddr_dqs;	 
wire [23:0] lcd_d;
wire [10:0] cx;
wire [10:0] cy;
assign lcd_d = {cy[4:0],3'b0,cx[10:5],2'b0,cx[4:0],3'b0};
c902_ctrl_top c902_inst(
	.CLK_IN(clk),
	.RST_N(rst_n),
	.CLK_P(clk_2),
	.DATA_LCD_IN(lcd_d),
	.DE_LCD_IN(de_test),
	.VSYNC(vsync_test),
	.DDR_DQ(ddr_dq),
	.DDR_DQS(ddr_dqs),
	.DDR_CK_P(ddr_ckp),
	.DDR_CK_N(ddr_ckn),
	.DDR_CKE(ddr_cke),
	.DDR_WE_N(ddr_wen),
	.DDR_RAS_N(ddr_rasn),
	.DDR_CAS_N(ddr_casn),
	.DDR_CS_N(ddr_csn),
	.DDR_BA(ddr_ba),
	.DDR_ADDR(ddr_add),
	.DDR_DM(ddr_dm)
    );
	 
de_gen xsga_inst_test(     
     .xclk(clk_2),
     .vsync(vsync_test),
	  .hsync(hsync_test),
     .de(de_test),
	  .cnt_x(cx),
	  .cnt_y(cy)
     );
	  
ddr ddr_inst(
.Clk(ddr_ckp), 
.Clk_n(ddr_ckn), 
.Cke(ddr_cke), 
.Cs_n(ddr_csn), 
.Ras_n(ddr_rasn), 
.Cas_n(ddr_casn), 
.We_n(ddr_wen), 
.Ba(ddr_ba) , 
.Addr({1'b0,ddr_add}), 
.Dm(ddr_dm), 
.Dq(ddr_dq), 
.Dqs(ddr_dqs)
);

endmodule
