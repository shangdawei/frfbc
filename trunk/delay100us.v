`timescale 1ns / 1ps
/*
** -----------------------------------------------------------------------------**
** delay100us.v
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
module delay100us(
clk,
rst_n,
delay100
);
input clk;
input rst_n;
output delay100;
reg [13:0] counter;

assign delay100 =(counter[13:12]==2'b11)?1'b1:1'b0;

always@(posedge clk or negedge rst_n)
begin
   if(~rst_n)
      counter <= 4'b0;
   else
      if(counter[13:12]!=2'b11)counter <= counter + 1;
end

endmodule
