/*
** -----------------------------------------------------------------------------**
** ddr_top.v
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
module ddr_top (
                //Inout
                ddr_dq,
                ddr_dqs,
                sysdi,
					 sysdo,
                // Outputs
                sys_init_done,  
                ddr_dqm, 
                ddr_wen, 
                ddr_rasn, 
                ddr_csn, 
                ddr_cke, 
                ddr_casn, 
                ddr_ba, 
                ddr_add, 
//                ddr_clk, 
//                ddr_clkn,
                // Inputs
                sys_r_wn, 
                sys_dly_200us,  
                sys_adsn, 
                sys_add, 
					 sys_out_en,
					 sys_in_en,
                reset_n, 
                clk,
					 clk_dqs
                );

`include "ddr_par.v"


input                   clk;             // System clk
input							clk_dqs;

input                   reset_n;         // System reset
input [14:0]   			sys_add;         // System address 
input                   sys_adsn;        // System address strobe
input                   sys_dly_200us;   // Signal from system to be asseted after 200us of stable clk
input                   sys_r_wn;        // Read (high) and write low

output [DDR_A_WIDTH-1:0]ddr_add;         // DDR address
output [DDR_BA_WIDTH-1:0]ddr_ba;         // DDR bank address
output                  ddr_casn;        // DDR cas signal
output                  ddr_cke;         // DDR clock enable
output                  ddr_csn;         // DDR chip select
output                  ddr_rasn;        // DDR rasn
output                  ddr_wen;         // DDR write enable
output [DSIZE/16-1:0]   ddr_dqm;         // DDR data mask signal
output                  sys_init_done;   // DDR intialsation done
output                  sys_in_en;        // Ready signal to system
output                  sys_out_en;
//output                  ddr_clk;         // DDR clock
//output                  ddr_clkn;        // DDR clock -ve

inout [DSIZE/2-1:0]     ddr_dq;          // DDR data in/out
inout [DSIZE/16-1:0]    ddr_dqs;         // DDR data strobe
input [DSIZE-1:0]            sysdi;            // System data in/out
output [DSIZE-1:0]           sysdo;

wire [RA_MSB:CA_LSB]    addr;                 
wire [3:0]              cstate;               
wire [3:0]              istate;               
wire                    wren;                 
wire [DSIZE-1:0]        sys_datain;           
wire [DSIZE/2-1:0]      dqout;                
wire                    dqout_en;             
wire [DSIZE/16-1:0]     dqsout;               
wire [DSIZE/2-1:0]      dqin;                 
wire [DSIZE-1:0]        sys_dataout;       
wire dqsout_en;
wire readrdy;
/*
OBUFDS CLKDDR_BUFG_INST1
(
      .I  (clk_ddr),
      .O  (ddr_clk),
      .OB (ddr_clkn)
);
	*/	
ddr_ctrl u1_ddr_ctrl (
                      /*AUTOINST*/
                      // Outputs
                      .sys_init_done    (sys_init_done),
                      .istate           (istate[3:0]),
                      .cstate           (cstate[3:0]),
                      .wren             (wren),
                      .addr             (addr[RA_MSB:CA_LSB]),
                      // Inputs
                      .clk              (clk),
                      .reset_n          (reset_n),
                      .sys_r_wn         (sys_r_wn),
                      .sys_adsn         (sys_adsn),
                      .sys_dly_200us    (sys_dly_200us),
                      .sys_add          (sys_add),
                      .readrdy          (readrdy));


ddr_data u1_ddr_data (
                      /*AUTOINST*/
                      // Outputs
                      .dqout_en         (dqout_en),
                      .dqout            (dqout[DSIZE/2-1:0]),
                      .dqsout           (ddr_dqs),
                      .dqsout_en        (dqsout_en),
                      .sys_datain_en    (sys_in_en),
                      .sys_dataout      (sys_dataout),
							 .sys_dataout_en   (sys_out_en),
                      .dqm_out          (ddr_dqm[DSIZE/16-1:0]),
                      // Inputs
                      .clk              (clk),
                      .clk_dqs          (clk_dqs),
                      .reset_n          (reset_n),
                      .cstate           (cstate[3:0]),
                      .wren             (wren),
                      .sys_datain       (sys_datain),
                      .dqin             (dqin[DSIZE/2-1:0]),
                      .readrdy          (readrdy));


ddr_sig u1_ddr_sig   (
                      /*AUTOINST*/
                      // Outputs
                      .ddr_cke          (ddr_cke),
                      .ddr_csn          (ddr_csn),
                      .ddr_rasn         (ddr_rasn),
                      .ddr_casn         (ddr_casn),
                      .ddr_wen          (ddr_wen),
                      .ddr_ba           (ddr_ba[DDR_BA_WIDTH-1:0]),
                      .ddr_add          (ddr_add[DDR_A_WIDTH-1:0]),
                      // Inputs
                      .clk              (clk),
                      .reset_n          (reset_n),
                      .addr             (addr[RA_MSB:CA_LSB]),
                      .istate           (istate[3:0]),
                      .cstate           (cstate[3:0]));


//===============================================================
// DDR interface (READ & WRITE
//===============================================================

// Read data
assign  dqin[DSIZE/2-1:0]        = ddr_dq;                     

// Write data

assign ddr_dq = dqout_en ? dqout : {DSIZE/2{1'bz}};
//assign ddr_dqs = dqsout_en?dqsout:2'bz;
assign sys_datain[DSIZE-1:0] = sysdi;

assign sysdo = sys_dataout;



endmodule

                