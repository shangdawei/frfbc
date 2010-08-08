`timescale 1ns / 1ps
/*
** -----------------------------------------------------------------------------**
** frfb_io_ctrl.v
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
module c902_io_ctrl(
clk,
rst_n,
sys_addr,
sys_adsn,
sys_r_wn,
sys_init_done,
cnt_in,
cnt_out,
lcd_in_svsync,
lcd_out_svsync,
rd,
wr
    );

input             clk;
input             rst_n;
output	[14:0]	sys_addr;
output				sys_adsn;
output				sys_r_wn;
input					sys_init_done;
input					cnt_in;
input					cnt_out;
input					lcd_in_svsync;
input					lcd_out_svsync;
input             wr;
input             rd;

reg					sys_adsn;
reg					sys_r_wn;
reg    	[2:0]    state;
reg    	[2:0]    next_state;reg      [14:0]	addr_in_i;
reg      [14:0]	addr_out_i;
reg               ch;

reg               addi_add;
reg               addo_add;

parameter s_IDLE      = 3'b000;
parameter s_LCDIN     = 3'b001;
parameter s_LCDIN_W1  = 3'b010;
parameter s_LCDIN_W2  = 3'b011;
parameter s_LCDOUT    = 3'b100;
parameter s_LCDOUT_W1 = 3'b101;
parameter s_LCDOUT_W2 = 3'b110;

assign sys_addr = ch?addr_in_i:addr_out_i;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		state <= s_IDLE;
	else
		case(state)
			s_IDLE: begin
				if(sys_init_done && cnt_in) state <= s_LCDIN;
				else if(sys_init_done && (~cnt_out)) state <= s_LCDOUT;
			end
			s_LCDIN: begin
				state <= s_LCDIN_W1;
			end
			s_LCDIN_W1: begin
				if(rd) state <= s_LCDIN_W2;
			end
			s_LCDIN_W2: begin
				if(~rd)  state <= s_IDLE;
			end
			s_LCDOUT: begin
				state <= s_LCDOUT_W1;
			end
			s_LCDOUT_W1: begin
				if(wr) state <= s_LCDOUT_W2;
			end
			s_LCDOUT_W2: begin
				if(~wr) state <= s_IDLE;
			end
			
		endcase

end

always @(posedge clk or negedge rst_n) begin
   if(~rst_n) begin
		sys_r_wn 	<= 1'b1;
		sys_adsn 	<= 1'b1;
		ch       	<= 1'b0;
		addr_in_i	<= 15'b0;
		addr_out_i	<= 15'b0;
	end else begin
		case(state)
			s_IDLE:			begin
				sys_r_wn 	<= 1'b1;
				sys_adsn 	<= 1'b1;
				if(~lcd_in_svsync)addr_in_i <=  15'h0000;
				if(~lcd_out_svsync)addr_out_i <=  15'h0000;
			end
			s_LCDIN:  		begin
				sys_adsn 	<= 1'b0;
				sys_r_wn 	<= 1'b0;
				ch				<= 1'b1;
				addr_in_i <= addr_in_i+1;
			end
			s_LCDIN_W1: 	begin
				sys_r_wn 	<= 1'b0;
				sys_adsn 	<= 1'b1;
				ch				<= 1'b1;
			end
			s_LCDIN_W2:    begin
				sys_r_wn 	<= 1'b0;
				sys_adsn 	<= 1'b1;
				ch				<= 1'b1;
			end
			s_LCDOUT: 		begin
				sys_r_wn 	<= 1'b1;
				sys_adsn 	<= 1'b0;
				ch				<= 1'b0;
				addr_out_i  <= addr_out_i + 1;
			end
			s_LCDOUT_W1:   begin
				ch				<= 1'b0;
				sys_r_wn 	<= 1'b1;
				sys_adsn 	<= 1'b1;
			end
			s_LCDOUT_W2:	begin
				sys_r_wn 	<= 1'b1;
				sys_adsn 	<= 1'b1;
				ch				<= 1'b0;
			end
			default:begin
				sys_r_wn 	<= 1'b1;
				sys_adsn 	<= 1'b1;
				ch       	<= 1'b0;
			end
		endcase
	end
end


endmodule
