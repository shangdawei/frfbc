`timescale 1ns / 1ps
/*
** -----------------------------------------------------------------------------**
** vga_gen.v
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
module vga_gen(     
     xclk,
     hsync,
     vsync,
     de,
     cnt_x,
     cnt_y
     );
parameter h_front = 24;
parameter h_syncpulse = 56;
parameter h_back  = 124;
parameter h_line  = 844;
parameter h_enable = 640;
parameter v_front = 1;
parameter v_syncpulse = 3;
parameter v_back  = 38;
parameter v_line  = 1066;
parameter v_enable = 1024;

input xclk;
output hsync, vsync;
output de;
output [10:0] cnt_x;
output [10:0] cnt_y;

reg [10:0] cnt_x = 11'b0;
reg [10:0] cnt_y = 11'b0;
reg de;
wire CounterXmaxed = (cnt_x==h_line);

assign hsync = !(cnt_x>=h_line-h_syncpulse-h_back&cnt_x<h_line-h_back);
assign vsync = !(cnt_y>=v_line-v_syncpulse-v_back&cnt_y<v_line-v_back); 

always @(posedge xclk)
if(CounterXmaxed)
	cnt_x <= 1;
else
	cnt_x <= cnt_x + 1;

always @(posedge xclk)
  if(CounterXmaxed)
  if(cnt_y==v_line)
    cnt_y <= 0;
  else
    cnt_y <= cnt_y + 1;

always @(posedge xclk)
if(de==0)
	de <= (CounterXmaxed) && (cnt_y<v_enable);
else
	de <= !(cnt_x==h_enable);

endmodule
