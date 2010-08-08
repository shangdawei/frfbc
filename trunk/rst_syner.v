`timescale 1ns / 1ps
/*
** -----------------------------------------------------------------------------**
** rst_syner.v
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
module rst_syner(
clk,
async_n,
ssync_n,
dcm_lock
    );
input clk;
input async_n;
input dcm_lock;
output ssync_n;
reg ssync_n;
reg ff;

always @(posedge clk or negedge async_n)
if(~async_n)
{ssync_n,ff} <= 2'b0;
else
{ssync_n,ff} <= (dcm_lock)?{ff,1'b1}:1'b0;


endmodule

module syner(
clk,
async_n,
ssync_n
    );
input clk;
input async_n;
output ssync_n;
reg ssync_n;
reg ff;

always @(posedge clk or negedge async_n)
if(~async_n)
{ssync_n,ff} <= 2'b0;
else
{ssync_n,ff} <= {ff,1'b1};


endmodule