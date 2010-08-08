/*
** -----------------------------------------------------------------------------**
** ddr_sig.v
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

`define DDR_COMMAND_I  {ddr_csn_i, ddr_rasn_i, ddr_casn_i, ddr_wen_i}
`define DDR_COMMAND    {ddr_csn,   ddr_rasn,   ddr_casn,   ddr_wen}

module ddr_sig(
               clk,
               reset_n,
               addr,
               istate,
               cstate,
               ddr_cke,    // ddr clock enable
               ddr_csn,    // ddr chip select
               ddr_rasn,   // ddr row address
               ddr_casn,   // ddr column select
               ddr_wen,    // ddr write enable
               ddr_ba,     // ddr bank address
               ddr_add     // ddr address
               );

`include "ddr_par.v"

//---------------------------------------------------------------------
// inputs
//
input                     clk;
input                     reset_n;
input [RA_MSB:CA_LSB]     addr;
input [3:0]               istate;
input [3:0]               cstate;

//---------------------------------------------------------------------
// outputs
//
output                    ddr_cke;
output                    ddr_csn;
output                    ddr_rasn;
output                    ddr_casn;
output                    ddr_wen;
output [DDR_BA_WIDTH-1:0] ddr_ba;
output [DDR_A_WIDTH-1:0]  ddr_add;

reg                       ddr_cke /*synthesis dout="" */ ;
reg                       ddr_csn /*synthesis dout="" */;
reg                       ddr_rasn /*synthesis dout="" */;
reg                       ddr_casn /*synthesis dout="" */;
reg                       ddr_wen /*synthesis dout="" */;
reg [DDR_BA_WIDTH-1:0]    ddr_ba /*synthesis dout="" */;
reg [DDR_A_WIDTH-1:0]     ddr_add /*synthesis dout="" */;


reg                       ddr_cke_i;
reg                       ddr_csn_i;
reg                       ddr_rasn_i;
reg                       ddr_casn_i;
reg                       ddr_wen_i;
reg [DDR_BA_WIDTH-1:0]    ddr_ba_i;
reg [DDR_A_WIDTH-1:0]     ddr_add_i;

wire                      autoprecharge;

assign autoprecharge = (addr[7:3]==5'b10111)?1'b1:1'b0;

//---------------------------------------------------------------------
// DDR DDRAM Control Singals
//
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      `DDR_COMMAND_I    <= INHIBIT;
      ddr_cke_i         <= 1'b0;
      ddr_ba_i          <= 2'b11;
      ddr_add_i         <= 12'b1111_1111_1111;
   end else begin
      case (istate)
        i_IDLE: begin
           `DDR_COMMAND_I    <= NOP;
           ddr_cke_i         <= 1'b0;
           ddr_ba_i          <= 2'b11;
           ddr_add_i         <= 12'b1111_1111_1111;
        end      
        
        i_tRP,
        i_tRFC1,
        i_tRFC2,
        i_tMRD,
        i_NOP: begin
           `DDR_COMMAND_I    <= NOP;
           ddr_cke_i         <= 1;
           ddr_ba_i          <= 2'b11;
           ddr_add_i         <= 12'b1111_1111_1111;
        end
        i_PRE: begin
           `DDR_COMMAND_I    <= PRECHARGE;
           ddr_cke_i         <= 1;
           ddr_ba_i          <= 2'b11;
           ddr_add_i         <= 12'b1111_1111_1111;
        end
        i_AR1,
        i_AR2: begin
           `DDR_COMMAND_I    <= AUTO_REFRESH;
           ddr_cke_i         <= 1;
           ddr_ba_i          <= 2'b11;
           ddr_add_i         <= 12'b1111_1111_1111;
        end
        i_EMRS: begin
           `DDR_COMMAND_I    <= LOAD_MODE_REGISTER;
           ddr_cke_i         <= 1;
           ddr_ba_i          <= 2'b01; //Extended mode register
           ddr_add_i         <= {10'b0,DRIVE_STRENGTH,DLL_ENABLE};
        end
        
        i_MRS: begin
           `DDR_COMMAND_I    <= LOAD_MODE_REGISTER;
           ddr_cke_i         <= 1;
           ddr_ba_i          <= 2'b00;
           ddr_add_i         <= {
                                 5'b00010,
                                 MR_CAS_Latency,
                                 MR_Burst_Type,
                                 MR_Burst_Length
                                 };
        end

        i_ready: begin

           case (cstate)
             c_idle,
             c_tRCD,
             c_tRFC,
             c_cl,
             c_rdata,
             c_wdata:  begin
                `DDR_COMMAND_I    <= NOP;
                ddr_cke_i         <= 1;
                ddr_ba_i          <= 2'b11;
                ddr_add_i         <= 12'b1111_1111_1111;
             end
             c_ACTIVE: begin
                `DDR_COMMAND_I    <= ACTIVE;
                ddr_cke_i         <= 1;
                ddr_ba_i          <= addr[BA_MSB:BA_LSB];//bank
                ddr_add_i         <= addr[RA_MSB:RA_LSB];//row
             end
             c_READA:  begin
                `DDR_COMMAND_I    <= READ;
                ddr_cke_i         <= 1;
                ddr_ba_i          <= addr[BA_MSB:BA_LSB];//bank
                ddr_add_i         <= {
                                      //addr[CA_MSB],//column
                                      autoprecharge,
												  1'b0, //enable auto precharge
                                      addr[CA_MSB:CA_LSB]//column
                                      };
             end
             c_WRITEA: begin
                `DDR_COMMAND_I    <= WRITE;
                ddr_cke_i         <= 1;
                ddr_ba_i          <= addr[BA_MSB:BA_LSB];//bank
                ddr_add_i         <= {
                                      //addr[CA_MSB],//column (11)
                                      autoprecharge,
												  1'b0, //enable auto precharge (10)
                                      addr[CA_MSB:CA_LSB]//column (0-9)
                                      };
             end
           c_AR: begin
              `DDR_COMMAND_I    <= AUTO_REFRESH;
              ddr_cke_i         <= 1;
              ddr_ba_i          <= 2'b11;
              ddr_add_i         <= 12'b1111_1111_1111;
           end
             default:  begin
                `DDR_COMMAND_I    <= NOP;
                ddr_cke_i         <= 1;
                ddr_ba_i          <= 2'b11;
                ddr_add_i         <= 12'b1111_1111_1111;
             end
           endcase // case(cstate)
        end
        default: begin
           `DDR_COMMAND_I    <= NOP;
           ddr_cke_i         <= 1;
           ddr_ba_i          <= 2'b00;
           ddr_add_i         <= 12'b0000_0000_0000;
        end
      endcase
   end
end



always @(negedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      `DDR_COMMAND    <= INHIBIT;
      ddr_cke         <= 1;
      ddr_ba          <= 2'b00;
      ddr_add         <= 12'b0000_0000_0000;
   end else begin
      `DDR_COMMAND    <= `DDR_COMMAND_I;
      ddr_cke         <= ddr_cke_i;
      ddr_ba          <= ddr_ba_i;
      ddr_add         <= ddr_add_i;
      
   end   
end
      
endmodule

