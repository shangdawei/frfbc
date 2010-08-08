/*
** -----------------------------------------------------------------------------**
** ddr_par.v
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

parameter tDLY = 2; // 2ns delay for simulation purpose

//---------------------------------------------------------------------
// DDRAM mode register definition
//

// Write Burst Mode
parameter Programmed_Length = 1'b0;
parameter Single_Access     = 1'b1;

// Operation Mode
parameter Standard          = 2'b00;

// CAS Latency
parameter Latency_2         = 3'b010;
parameter Latency_3         = 3'b011;
parameter Latency_25        = 3'b110;

// Burst Type
parameter Sequential        = 1'b0;
parameter Interleaved       = 1'b1;

// Burst Length
parameter Length_2          = 3'b001;
parameter Length_4          = 3'b010;
parameter Length_8          = 3'b011;


// Drive strength

parameter NORMAL            = 1'b0;
parameter REDUCED           = 1'b1;

// DLL

parameter DLL_ENABLE        = 1'b0;
parameter DLL_DISABLE       = 1'b1;

//---------------------------------------------------------------------
// User modifiable parameters
//

/****************************
* Mode register setting
****************************/

parameter MR_Write_Burst_Mode =    Programmed_Length;
                                // Single_Access;

parameter MR_Operation_Mode   =    Standard;

// Latecy_3 (cas latency 3 supported only in DDR 400 devices)

parameter MR_CAS_Latency      =  Latency_2;
                                //Latency_25;
                                // Latency_3;

parameter MR_Burst_Type       =    Sequential;
                                // Interleaved;


parameter MR_Burst_Length     =  //Length_2;
                                 //Length_4;
                                 Length_8;
  
// Indicates data width on the user side
// Data width on the DDR side will be half

parameter DSIZE           = 32;


// DRIVE STRENGTH (applies for x16 DDR's)
parameter DRIVE_STRENGTH  = NORMAL;
                            // REDUCED;

  

/****************************
* Bus width setting
****************************/

//
//           23 ......... 12     11 ....... 10      9 .........0  
// sys_A  : MSB <-------------------------------------------> LSB
//
// Row    : RA_MSB <--> RA_LSB
// Bank   :                    BA_MSB <--> BA_LSB
// Column :                                       CA_MSB <--> CA_LSB
//

parameter RA_MSB = 23;
parameter RA_LSB = 11;

parameter BA_MSB = 10;
parameter BA_LSB = 9;

parameter CA_MSB =  8;
parameter CA_LSB =  0;

parameter DDR_BA_WIDTH =  2; // BA0,BA1
parameter DDR_A_WIDTH  = 12; // A0-A11

/****************************
* DDRAM AC timing spec (MT46v16m8 -5B)
****************************/

parameter tCK  = 7;
parameter tMRD = 15;
parameter tRP  = 20;
parameter tRFC = 75;
parameter tRCD = 20;
parameter tWR  = tCK + 15;
parameter tDAL = tWR + tRP;

//---------------------------------------------------------------------
// Clock count definition for meeting DDDRAM AC timing spec
//

parameter NUM_CLK_tMRD = 2;         // (tMRD/tCK = 15/7.5)
parameter NUM_CLK_tRP  = 3;         // (tRP/tCK  = 20/7.5)
parameter NUM_CLK_tRFC = 10;        // (tRFC/tCK = 75/7.5)
parameter NUM_CLK_tRCD = 2;         // (tRCD/tCK = 20/7.5)
parameter NUM_CLK_tDAL = 7;         // (tDAL/tCK = 7.5+15+20/7.5)

// tDAL needs to be satisfied before the next ddram ACTIVE command can
// be issued. State c_tDAL of CMD_FSM is created for this purpose.
// However, states c_idle, c_ACTIVE and c_tRCD need to be taken into
// account because ACTIVE command will not be issued until CMD_FSM
// switch from c_ACTIVE to c_tRCD. NUM_CLK_WAIT is the version after
// the adjustment.
parameter NUM_CLK_WAIT = (NUM_CLK_tDAL < 3) ? 0 : NUM_CLK_tDAL - 3;

parameter NUM_CLK_CL    = (MR_CAS_Latency == Latency_2)  ? 2 :
                          (MR_CAS_Latency == Latency_25) ? 3 :
                          (MR_CAS_Latency == Latency_3)  ? 3 :
                          2;  // default

parameter NUM_CLK_READ  = (MR_Burst_Length == Length_2) ? 1 :
                          (MR_Burst_Length == Length_4) ? 2 :
                          (MR_Burst_Length == Length_8) ? 4 :
                          4; // default

parameter NUM_CLK_WRITE = (MR_Burst_Length == Length_2) ? 1 :
                          (MR_Burst_Length == Length_4) ? 2 :
                          (MR_Burst_Length == Length_8) ? 4 :
                          4; // default
								  
parameter NUM_CLK_RUN   =  1;

parameter NUM_RRUN_CNT	= 24;
parameter NUM_WRUN_CNT  = 25;

//---------------------------------------------------------------------
// INIT_FSM state variable assignments (gray coded)
//

parameter i_IDLE  = 4'b0000;
parameter i_NOP   = 4'b0001;
parameter i_PRE   = 4'b0010;
parameter i_tRP   = 4'b0011;
parameter i_EMRS  = 4'b0100;
parameter i_tMRD  = 4'b0101;
parameter i_MRS   = 4'b0110;      
parameter i_AR1   = 4'b0111;
parameter i_tRFC1 = 4'b1000;
parameter i_AR2   = 4'b1001;
parameter i_tRFC2 = 4'b1010;
parameter i_ready = 4'b1011;
parameter i_wait  = 4'b1100;

//---------------------------------------------------------------------
// CMD_FSM state variable assignments (gray coded)
//

parameter c_idle   = 4'b0000;
parameter c_tRCD   = 4'b0001;
parameter c_cl     = 4'b0010;
parameter c_rdata  = 4'b0011;
parameter c_wdata  = 4'b0100;
parameter c_tRFC   = 4'b0101;
parameter c_tDAL   = 4'b0110;
parameter c_ACTIVE = 4'b1000;
parameter c_READA  = 4'b1001;
parameter c_WRITEA = 4'b1010;
parameter c_AR     = 4'b1011;
parameter c_PRE    = 4'b1100;
parameter c_wPRE    = 4'b1101;
parameter c_tWR    = 4'b1110;

//---------------------------------------------------------------------
// DDRAM commands (ddr_csn, ddr_rasn, ddr_casn, ddr_wen)
//

parameter INHIBIT            = 4'b1111;
parameter NOP                = 4'b0111;
parameter ACTIVE             = 4'b0011;
parameter READ               = 4'b0101;
parameter WRITE              = 4'b0100;
parameter BURST_TERMINATE    = 4'b0110;
parameter PRECHARGE          = 4'b0010;
parameter AUTO_REFRESH       = 4'b0001;
parameter LOAD_MODE_REGISTER = 4'b0000;

// Refresh counter selection.
// Auto refresh requirements are for 128Mbit and 256Mbit/512Mbit/1Gbit parts.
// For 128Mbit part, 4Krows in 64ms = 1 row every 15.625us.
// For 256Mbit/512Mbit/1Gbit parts 8krows in 64ms = 1 row every 7.8125us.

// 100 Mhz
//==========
// For 128Mbit part
// Refresh interval = 100 x 10^6 X 15.625 X 10^-6 = 1562.5 (say 1500)

// 256Mbit/512Mbit/1Gbit parts.
// Refresh interval = 100 x 10^6 X 7.8125 X 10^-6 = 781.25 (say 750)


// 133 Mhz
//==========
// For 128Mbit part
// Refresh interval = 133 x 10^6 X 15.625 X 10^-6 = 2078 (say 2000)

// 256Mbit/512Mbit/1Gbit parts.
// Refresh interval = 133 x 10^6 X 7.8125 X 10^-6 = 1039 (say 1000)


parameter REF_INT_128MBIT_100MHZ    = 1500;
parameter REF_INT_NON128MBIT_100MHZ = 750;

parameter REF_INT_128MBIT_133MHZ    = 2000;
parameter REF_INT_NON128MBIT_133MHZ = 1000;

// Select one of the required Refresh interval

parameter REF_INTERVAL = // REF_INT_128MBIT_100MHZ;
                         // REF_INT_NON128MBIT_100MHZ;
                            REF_INT_128MBIT_133MHZ;
                         // REF_INT_NON128MBIT_133MHZ;    
          