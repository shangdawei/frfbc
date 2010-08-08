/*
** -----------------------------------------------------------------------------**
** frfb_ctrl_top.v
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

module c902_ctrl_top(
	CLK_IN,
	RST_N,
	CLK_P,
	DATA_LCD_IN,
	DE_LCD_IN,
	VSYNC,
	DDR_DQ,
	DDR_DQS,
	DDR_CK_P,
	DDR_CK_N,
	DDR_CKE,
	DDR_WE_N,
	DDR_RAS_N,
	DDR_CAS_N,
	DDR_CS_N,
	DDR_BA,
	DDR_ADDR,
	DDR_DM,
	LVDS_DATA_P,
	LVDS_DATA_N,
	LVDS_CLKA_P,
	LVDS_CLKA_N,
	LVDS_DATB_P,
	LVDS_DATB_N,
	LVDS_CLKB_P,
	LVDS_CLKB_N
    );
	 
input					CLK_IN;
input 				RST_N;
input 				CLK_P;
input		[23:0]	DATA_LCD_IN;
input					DE_LCD_IN;
input					VSYNC;

inout		[15:0]	DDR_DQ;
inout		[1:0]		DDR_DQS;
output				DDR_CK_P;
output				DDR_CK_N;
output				DDR_CKE;
output				DDR_WE_N;
output				DDR_RAS_N;
output				DDR_CAS_N;
output				DDR_CS_N;
output	[1:0]		DDR_BA;
output	[12:0]	DDR_ADDR;
output	[1:0]		DDR_DM;

output	[3:0]		LVDS_DATA_P;
output	[3:0]		LVDS_DATA_N;
output				LVDS_CLKA_P;
output				LVDS_CLKA_N;
output	[3:0]		LVDS_DATB_P;
output	[3:0]		LVDS_DATB_N;
output				LVDS_CLKB_P;
output				LVDS_CLKB_N;

wire              reset_n;
wire              reset_n_2;

wire              lock_dcm_2;
wire					clk_54,clk_lvds_3p5,clk_108,clk_dqs;

wire              delay200;

wire					vsync_in;

wire		[31:0]		data_lcd;
wire					rd;
wire					wr;
wire		[31:0]	sys_data_i;
wire		[31:0]	sys_data_o;
//wire     [31:0]   sys_data_io;
wire		[14:0]	sys_addr;
wire					sys_adsn;
wire					sys_r_wn;
wire					sys_init_done;
wire					sys_rdyn;
wire		[8:0]		cnt_in;
wire		[8:0]		cnt_out;
wire					lcd_vsync_out;
wire 					lcd_hsync_out;
wire					wr_lcd_out;
wire     [15:0]   lcd_data_in_16;
wire		[31:0]	lcd_data_out_32;
wire		[47:0]	lcd_data_out_48;
wire     [11:0]   ddr_add;

wire					lcd_de_i;


assign lcd_data_in_16 = {DATA_LCD_IN[23:19],DATA_LCD_IN[15:10],DATA_LCD_IN[7:3]};

assign DDR_ADDR = {1'b0,ddr_add};
assign vsync_in = VSYNC;

reg clk_ddr_out_0;
reg clk_ddr_out_1;
wire clk_ddr_out;


ODDR2 ODDR_CKP(.D0(1'b1),.D1(1'b0),.C0(clk_108),.C1(~clk_108),.Q(clk_ddr_out),.CE(1'b1),.S(1'b0),.R(1'b0));

OBUFDS CLKDDR_BUFG_INST1
(
      .I  (clk_ddr_out),
      .O  (DDR_CK_P),
      .OB (DDR_CK_N)
);

clk_dcm dcm_inst_1(
				 .CLKIN_IN(CLK_IN), 
             .RST_IN(~RST_N), 
             .CLKDV_OUT(clk_54), 
             .CLKFX_OUT(clk_lvds_3p5), 
             .CLK0_OUT(clk_108), 
             .CLK270_OUT(clk_dqs), 
             .LOCKED_OUT(lock_dcm_2)
             );
FD FD_RST_N(.D(lock_dcm_2),.Q(reset_n_2),.C(clk_108));
//SRL16 SRL_RST(.D(lock_dcm_2),.Q(reset_n_2),.CLK(clk_108),.A0(1'b1),.A1(1'b1),.A2(1'b0),.A3(1'b0));

//SRL16 SRL_DE(.D(DE_LCD_IN),.Q(lcd_de_i),.CLK(CLK_P),.A0(1'b0),.A1(1'b0),.A2(1'b0),.A3(1'b0));
wire rd_fd0;
FD FD_RD_INST0(.D(rd),.Q(rd_fd0),.C(clk_108));

fifo_in fifo_in_inst(
	.wr_clk(CLK_P),
	.wr_en(DE_LCD_IN),
	//.wr_en(1'b0),
	.din(lcd_data_in_16),
	.rd_clk(clk_108),
	.rd_en(rd&rd_fd0),
	.dout(sys_data_i),
	.rd_data_count(cnt_in),
	.rst((~vsync_in)|(~reset_n_2))
);


delay100us delay_inst(
	.clk(clk_54),
	.rst_n(reset_n_2),
	.delay100(delay200)
);

c902_io_ctrl c902_io_inst(
	.clk(clk_108),
	.rst_n(reset_n_2),
	.sys_addr(sys_addr),
	.sys_adsn(sys_adsn),
	.sys_r_wn(sys_r_wn),
	.sys_init_done(sys_init_done),
	.cnt_in(cnt_in[8]),
	.cnt_out(cnt_out[8]),
	.lcd_in_svsync(vsync_in),
	.lcd_out_svsync(lcd_vsync_out),
	.rd(rd),
	.wr(wr)
);
	
ddr_top ddr_ctrl_inst(
   //Inout
   .ddr_dq(DDR_DQ),
   .ddr_dqs(DDR_DQS),
   .sysdi(sys_data_i),
   .sysdo(sys_data_o),
	// Outputs
   .sys_init_done(sys_init_done),  
   .ddr_dqm(DDR_DM), 
   .ddr_wen(DDR_WE_N), 
   .ddr_rasn(DDR_RAS_N), 
   .ddr_csn(DDR_CS_N), 
   .ddr_cke(DDR_CKE), 
   .ddr_casn(DDR_CAS_N), 
   .ddr_ba(DDR_BA), 
   .ddr_add(ddr_add), 
   // Inputs
   .sys_r_wn(sys_r_wn), 
   .sys_dly_200us(delay200),  
   .sys_adsn(sys_adsn), 
   .sys_add(sys_addr), 
	.sys_out_en(wr),
	.sys_in_en(rd),
   .reset_n(reset_n_2), 
   .clk(clk_108),
   .clk_dqs(clk_dqs)
   );
	
wire wr_fd0;
FD FD_WR_INST0(.D(wr),.Q(wr_fd0),.C(clk_108));

fifo_out fifo_out_inst(
	.wr_clk(clk_108),
	.wr_en(wr&wr_fd0),
	.din(sys_data_o),
	.rd_clk(clk_54),
	.rd_en(lcd_de_out),
	.dout(lcd_data_out_32),
	.wr_data_count(cnt_out),
	.rst(~lcd_vsync_out)
	);
	
wire [10:0] cnt_y;
assign lcd_data_out_48 = cnt_y[10]?48'b0:{	
   								lcd_data_out_32[15:11],3'b0,
									lcd_data_out_32[10:5] ,2'b0,
									lcd_data_out_32[4:0]  ,3'b0,
                           lcd_data_out_32[31:27],3'b0,
									lcd_data_out_32[26:21],2'b0,
									lcd_data_out_32[20:16],3'b0};
									
vga_gen sxga_inst(     
     .xclk(clk_54),
     .vsync(lcd_vsync_out),
	  .hsync(lcd_hsync_out),
     .de(lcd_de_out),
     .cnt_y(cnt_y)
     );
wire lcd_de_out_2;
FD FD_LCD_DE_OUT_INST(.D(lcd_de_out),.Q(lcd_de_out_2),.C(clk_54));	  
top4_tx lvds_tx_inst(
	.clkin(clk_54), 				// clock in
	.clkx3p5(clk_lvds_3p5),
	.lcd_data(lcd_data_out_48),
	.lcd_de(lcd_de_out_2),
	.lcd_vsync(lcd_vsync_out),
	.lcd_hsync(lcd_hsync_out),
	.rstin_n(reset_n_2),				// reset (active low)
	.dataouta_p(LVDS_DATA_P), 
	.dataouta_n(LVDS_DATA_N),		// lvds data outputs
	.dataoutb_p(LVDS_DATB_P), 
	.dataoutb_n(LVDS_DATB_N),
	.clkouta1_p(LVDS_CLKA_P),  
	.clkouta1_n(LVDS_CLKA_N),
	.clkoutb1_p(LVDS_CLKB_P),  
	.clkoutb1_n(LVDS_CLKB_N)
);	



endmodule

