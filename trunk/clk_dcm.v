/*
** -----------------------------------------------------------------------------**
** clk_dcm.v
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

module clk_dcm(CLKIN_IN, 
             RST_IN, 
             CLKDV_OUT, 
             CLKFX_OUT, 
             CLKIN_IBUFG_OUT, 
             CLK0_OUT, 
             CLK270_OUT, 
             LOCKED_OUT);

    input CLKIN_IN;
    input RST_IN;
   output CLKDV_OUT;
   output CLKFX_OUT;
   output CLKIN_IBUFG_OUT;
   output CLK0_OUT;
   output CLK270_OUT;
   output LOCKED_OUT;
   
   wire CLKDV_BUF;
   wire CLKFB_IN;
   wire CLKFX_BUF;
   wire CLKIN_IBUFG;
   wire CLK0_BUF;
   wire CLK270_BUF;
   wire GND_BIT;
   
   assign GND_BIT = 0;
   assign CLKIN_IBUFG_OUT = CLKIN_IBUFG;
   assign CLK0_OUT = CLKFB_IN;
   BUFG CLKDV_BUFG_INST (.I(CLKDV_BUF), 
                         .O(CLKDV_OUT));
   BUFG CLKFX_BUFG_INST (.I(CLKFX_BUF), 
                         .O(CLKFX_OUT));
   IBUFG CLKIN_IBUFG_INST (.I(CLKIN_IN), 
                           .O(CLKIN_IBUFG));
   BUFG CLK0_BUFG_INST (.I(CLK0_BUF), 
                        .O(CLKFB_IN));
   BUFG CLK270_BUFG_INST (.I(CLK270_BUF), 
                          .O(CLK270_OUT));
   DCM_SP DCM_SP_INST (.CLKFB(CLKFB_IN), 
                       .CLKIN(CLKIN_IBUFG), 
                       .DSSEN(GND_BIT), 
                       .PSCLK(GND_BIT), 
                       .PSEN(GND_BIT), 
                       .PSINCDEC(GND_BIT), 
                       .RST(RST_IN), 
                       .CLKDV(CLKDV_BUF), 
                       .CLKFX(CLKFX_BUF), 
                       .CLKFX180(), 
                       .CLK0(CLK0_BUF), 
                       .CLK2X(), 
                       .CLK2X180(CLK270_BUF), 
                       .CLK90(), 
                       .CLK180(), 
                       .CLK270(), 
                       .LOCKED(LOCKED_OUT), 
                       .PSDONE(), 
                       .STATUS());
   defparam DCM_SP_INST.CLK_FEEDBACK = "1X";
   defparam DCM_SP_INST.CLKDV_DIVIDE = 2.0;
   defparam DCM_SP_INST.CLKFX_DIVIDE = 4;
   defparam DCM_SP_INST.CLKFX_MULTIPLY = 7;
   defparam DCM_SP_INST.CLKIN_DIVIDE_BY_2 = "FALSE";
   defparam DCM_SP_INST.CLKIN_PERIOD = 9.259;
   defparam DCM_SP_INST.CLKOUT_PHASE_SHIFT = "NONE";
   defparam DCM_SP_INST.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
   defparam DCM_SP_INST.DFS_FREQUENCY_MODE = "LOW";
   defparam DCM_SP_INST.DLL_FREQUENCY_MODE = "LOW";
   defparam DCM_SP_INST.DUTY_CYCLE_CORRECTION = "TRUE";
   defparam DCM_SP_INST.FACTORY_JF = 16'hC080;
   defparam DCM_SP_INST.PHASE_SHIFT = 0;
   defparam DCM_SP_INST.STARTUP_WAIT = "FALSE";
endmodule
