/*
** -----------------------------------------------------------------------------**
** ddr_ctrl.v
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

module ddr_ctrl(
                clk,
                reset_n,
                sys_r_wn,
                sys_add,
                sys_adsn,
                sys_dly_200us,
                sys_init_done,
                istate,
                cstate,
                wren,
                addr,
                readrdy
                );

`include "ddr_par.v"

//---------------------------------------------------------------------
// inputs
//
input                     clk;
input                     reset_n;
input                     sys_r_wn;
input                     sys_adsn;
input                     sys_dly_200us;
input [14:0]			     sys_add;
                                   
//---------------------------------------------------------------------
// outputs
//
output                    sys_init_done;
output [3:0]              istate;
output [3:0]              cstate;
output                    wren;
output [RA_MSB:CA_LSB]    addr;
output                    readrdy;
//---------------------------------------------------------------------
// registers
//
reg                       sys_init_done;  // indicates sdr initialization is done
reg [3:0]                 istate;        // INIT_FSM state variables
reg [3:0]                 cstate;        // CMD_FSM state variables

reg [3:0]                 cs_clkcnt;
reg [7:0]                 i_clkcnt;
reg                       i_syncResetClkCNT; // reset i_clkcnt to 0
reg                       cs_syncResetClkCNT; // reset cs_clkcnt to 0
reg                       load_mrs_done;  // Load mode register done during intilaization
reg                       rd_wr_req_during_ref_req;
//reg [RA_MSB:CA_LSB]       addr;
reg                       wren;
reg [10:0]                q;
reg                       ref_req_c;
reg                       ref_req;
reg                       latch_ref_req;
reg                       ref_ack;
reg                       sys_adsn_r;
reg [14:0]       			  sys_add_r ;
reg                       sys_r_wn_r;
reg [4:0]                 runCNT;
reg [14:0]       			  addr_i;
reg                       readrdy;
//---------------------------------------------------------------------
// local definitions
//
`define endOf_tRP_i          i_clkcnt == NUM_CLK_tRP
`define endOf_tRFC_i         i_clkcnt == NUM_CLK_tRFC
`define endOf_tMRD_i         i_clkcnt == NUM_CLK_tMRD
`define endOf_tWAIT_i        i_clkcnt == 200

`define endOf_tRP          cs_clkcnt == NUM_CLK_tRP
`define endOf_tRFC         cs_clkcnt == NUM_CLK_tRFC
`define endOf_tMRD         cs_clkcnt == NUM_CLK_tMRD
`define endOf_tRCD         cs_clkcnt == NUM_CLK_tRCD
`define endOf_Cas_Latency  cs_clkcnt == NUM_CLK_CL 
`define endOf_Read_Burst   cs_clkcnt == NUM_CLK_READ - 1
`define endOf_Write_Burst  cs_clkcnt == NUM_CLK_WRITE 
`define endOf_tDAL         cs_clkcnt == NUM_CLK_WAIT

`define endOf_RRUN         runCNT    == 24
`define endOf_WRUN         runCNT    == 24
`define startOf_RRUN       cs_clkcnt == 0

assign addr = {addr_i,runCNT[4:0],3'b0};


//=======================================================================
// INIT_FSM state machine
//=======================================================================
always @(posedge clk or negedge reset_n) begin
  if (reset_n == 1'b0) begin
     istate           <= i_IDLE;
     load_mrs_done    <= 1'b0;
  end else
    case (istate)
      i_IDLE: begin    // wait for 200 us delay by checking sys_dly_200us
         if (sys_dly_200us) istate <=  i_NOP;
      end
      
      i_NOP: begin    // After 200us delay apply NOP and then do precharge all
         istate <=  i_PRE;
      end
      
      i_PRE: begin    // precharge all
           istate <=  i_tRP;
      end
      
      i_tRP: begin    // wait until tRP satisfied
         if (`endOf_tRP_i) 
           istate <=  load_mrs_done ? i_AR1 : i_EMRS;
      end

      i_EMRS: begin   //Enable DLL in Extended Mode Reg
         istate <=  i_tMRD;
      end

      i_tMRD: begin   // wait until tMRD satisfied
         if (`endOf_tMRD_i) 
           istate <=  load_mrs_done ? i_PRE : i_MRS;
      end

      i_MRS: begin    //Reset DLL in load Mode Reg
         load_mrs_done <= 1'b1;
         istate        <=  i_tMRD;
      end
      
      i_AR1: begin    // auto referesh
         istate <= i_tRFC1;
      end
      
      i_tRFC1: begin  // wait until tRFC satisfied
         if (`endOf_tRFC_i) istate <=  i_AR2;
      end
      
      i_AR2: begin    // auto referesh
         istate <=  i_tRFC2;
      end
      
      i_tRFC2: begin  // wait until tRFC satisfied
         if (`endOf_tRFC_i) istate <=  i_wait;
      end
		i_wait:  begin
		   if (`endOf_tWAIT_i) istate <= i_ready;
		end
      i_ready: begin    // stay at this state for normal operation
         istate <=  i_ready;
      end
      
      default: begin
         istate <=  i_NOP;
      end
    endcase
end

//=======================================================================
// sys_init_done generation
//=======================================================================
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
     sys_init_done <=  0;
   end else begin
     case (istate)
       i_ready: sys_init_done <=  1;
       default: sys_init_done <=  0;
     endcase
   end
end

//=======================================================================
// Latching the address and looking at
// READ or Write request during Refresh and address latching
//=======================================================================
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      rd_wr_req_during_ref_req    <= 1'b0;
      addr_i                        <= 15'b0;
      sys_adsn_r                  <= 1'b0;
      sys_add_r                   <= 15'b0;
      sys_r_wn_r                  <= 1'b0;
   end else begin

      sys_adsn_r <= sys_adsn;
      sys_add_r  <= sys_add;
      sys_r_wn_r <= sys_r_wn;
      
      // Store the address whenever there is address strobe
      if (!sys_adsn_r && sys_init_done) 
		  addr_i <= sys_add_r;
//		if (sys_init_done)
      

      // New (rd or wr) during refresh command getting serviced
      case (cstate)
        c_idle: begin
           if (!rd_wr_req_during_ref_req)
             if (!sys_adsn_r && latch_ref_req)
               rd_wr_req_during_ref_req <= 1'b1;
             else
               rd_wr_req_during_ref_req <= 1'b0;
        end
        // After completing write (c_tDAL)
        // Durinf c_tDAL, system can make a request and
        // refresh can be pending. 
        c_tRFC,
        c_tDAL,  
        c_AR: begin
           if (!sys_adsn_r)
             rd_wr_req_during_ref_req <= sys_init_done;
        end

        default: begin
           rd_wr_req_during_ref_req <= 1'b0;
        end
        
      endcase
   end
end
//=======================================================================
// CMD_FSM state machine
//=======================================================================

always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      cstate <=  c_idle;
      wren   <= 1'b0;
   end else begin
      case (cstate)
        c_idle:   // wait until refresh request or addr strobe asserted
          if (latch_ref_req && sys_init_done) 
            cstate <=  c_AR;
          else if ((!sys_adsn_r && sys_init_done) || rd_wr_req_during_ref_req) 
            cstate <=  c_ACTIVE;
        c_ACTIVE: // assert row/bank addr
          if (NUM_CLK_tRCD == 0)
            cstate <=  (sys_r_wn_r) ? c_READA : c_WRITEA;
          else 
            cstate <=  c_tRCD;
        c_tRCD:   // wait until tRCD satisfied
          if (`endOf_tRCD)
            cstate <=  (sys_r_wn_r) ? c_READA : c_WRITEA;
        c_READA:  // assert col/bank addr for read with auto-precharge
          cstate <=  c_cl;
        c_cl:     // CASn latency
          if (`endOf_Cas_Latency) begin 
             readrdy <= 1'b1;
//             if(runCNT==2)readrdy <= 1'b1;
				 if (`endOf_RRUN) begin 
					cstate <=  c_rdata;
				 end else begin
				   cstate <= c_READA;
				 end
			 end
        c_rdata:  // read cycle data phase
            if (`endOf_Read_Burst) begin 
				     cstate <=  c_idle;
                 readrdy<=1'b0;
				end
        c_WRITEA: begin // assert col/bank addr for write with auto-precharge
           cstate <=  c_wdata;
           wren   <= 1'b1;
        end
        c_wdata: begin  // write cycle data phase
           if(`endOf_WRUN) begin
			    if (`endOf_Write_Burst) begin
               cstate <=  c_tDAL;
               wren   <= 1'b0;
				 end 
			  end else if(cs_clkcnt == NUM_CLK_WRITE - 2) begin
				   cstate <=  c_WRITEA;
			  end else begin
			      cstate <=  c_wdata;
			  end
        end
        c_tDAL:   // wait until (tWR + tRP) satisfied before issuing next
          // SDRAM ACTIVE command
          if (`endOf_tDAL) cstate <=  c_idle;
        c_AR:     // auto-refresh
          cstate <=  (NUM_CLK_tRFC == 0) ? c_idle : c_tRFC;
        c_tRFC:   // wait until tRFC satisfied
          if (`endOf_tRFC) cstate <=  c_idle;
        default: begin
           cstate <=  c_idle;
           wren   <= 1'b0;
        end
      endcase
   end
end


always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      q       <= 0;
      ref_req <= 1'b0;
   end else begin
      q[0]    <= ~(q[10]^q[8]^ref_req_c);
      q[10:1] <= q[9:0];
      ref_req <= ref_req_c;
   end
end

always @ (q) begin
   if (REF_INTERVAL == REF_INT_128MBIT_100MHZ)
      /*477*/ref_req_c =  q[10]&~q[9]&~q[8]&~q[7]&q[6]&q[5]&q[4]&~q[3]&q[2]&q[1]&q[0];
   if (REF_INTERVAL == REF_INT_NON128MBIT_100MHZ)
     /*605*/ref_req_c = q[10]&q[9]&~q[8]&~q[7]&~q[6]&~q[5]&~q[4]&~q[3]&q[2]&~q[1]&q[0];
   if (REF_INTERVAL == REF_INT_128MBIT_133MHZ)
     /*300*/ref_req_c = ~q[10]&q[9]&q[8]&~q[7]&~q[6]&~q[5]&~q[4]&~q[3]&~q[2]&~q[1]&~q[0];
   if (REF_INTERVAL == REF_INT_NON128MBIT_133MHZ)
     /*350*/ref_req_c = ~q[10]&q[9]&q[8]&~q[7]&q[6]&~q[5]&q[4]&~q[3]&~q[2]&~q[1]&~q[0];  
end


always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      ref_ack       <= 0;
      latch_ref_req <= 1'b0;
   end else begin
      if (ref_req)
        latch_ref_req <= 1'b1;
      else if (ref_ack)
        latch_ref_req <= 1'b0;
        
      case (cstate)
        c_idle:
          ref_ack    <= sys_init_done && latch_ref_req;
        default:
          ref_ack    <= 1'b0;
      endcase
   end
end


//=======================================================================
// Clock Counter
//=======================================================================
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      cs_clkcnt <= 4'b0;
   end else begin
      if (cs_syncResetClkCNT) 
        cs_clkcnt <=  4'b0;
      else 
        cs_clkcnt <=  cs_clkcnt + 1'b1;
   end
end

always @(posedge clk or negedge reset_n) begin
  if (reset_n == 1'b0) begin
     runCNT <=  0;
  end else begin
    case (cstate)
		c_idle:runCNT <=  0;
//		c_idle:runCNT <=  sys_r_wn_r?5'b00001:5'b00001;
		c_READA:runCNT <=  runCNT+1;
      c_WRITEA:runCNT <=  runCNT+1;
	 endcase
  end
end

always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      i_clkcnt <= 8'b0;
   end else begin
      if (i_syncResetClkCNT) 
        i_clkcnt <=  8'b0;
      else 
        i_clkcnt <=  i_clkcnt + 1'b1;
   end
end

//=======================================================================
// istate syncResetClkCNT generation
//=======================================================================
always @(istate or i_clkcnt) begin
  case (istate)
    i_PRE:
      i_syncResetClkCNT =  (NUM_CLK_tRP == 0) ? 1 : 0;
    i_AR1,
    i_AR2:
      i_syncResetClkCNT =  (NUM_CLK_tRFC == 0) ? 1 : 0;
    i_tRP:
      i_syncResetClkCNT =  (`endOf_tRP_i) ? 1 : 0;
    i_tMRD:
      i_syncResetClkCNT =  (`endOf_tMRD_i) ? 1 : 0;
    i_tRFC1,
    i_tRFC2:
      i_syncResetClkCNT =  (`endOf_tRFC_i) ? 1 : 0;
	 i_wait:
	   i_syncResetClkCNT =  (`endOf_tWAIT_i) ? 1 : 0;
    default:
         i_syncResetClkCNT =  1;
  endcase
end

//=======================================================================
// cstate syncResetClkCNT generation
//=======================================================================
always @(cstate or cs_clkcnt) begin
   case (cstate)
     c_idle:
       cs_syncResetClkCNT =  1;
     c_ACTIVE:
       cs_syncResetClkCNT =  (NUM_CLK_tRCD == 0) ? 1 : 0;
     c_tRCD:
       cs_syncResetClkCNT =  (`endOf_tRCD) ? 1 : 0;
     c_tRFC:
       cs_syncResetClkCNT =  (`endOf_tRFC) ? 1 : 0;
     c_cl:
       cs_syncResetClkCNT =  (`endOf_Cas_Latency) ? 1 : 0;
     c_rdata:
       cs_syncResetClkCNT =  (cs_clkcnt == NUM_CLK_READ) ? 1 : 0;
     c_wdata:
       cs_syncResetClkCNT =  (`endOf_Write_Burst) ? 1 : 0;
     c_tDAL:
       cs_syncResetClkCNT =  (`endOf_tDAL) ? 1 : 0;
     
     default:
       cs_syncResetClkCNT =  1;
   endcase // case(cstate)
end



endmodule
                

                  



