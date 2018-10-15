//Begin Copied Code
//Source: http://outputlogic.com/
//This module is based on the code generator at the above website, but is modified to fit my program.
//I changed the output to d0 and delete the original output
//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com 
// This source file may be used and distributed without restriction 
// provided that this copyright statement is not removed from the file 
// and that any derivative work contains the original copyright notice 
// and the associated disclaimer. 
// 
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS 
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED	
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. 
//-----------------------------------------------------------------------------
module lfsr_counter(
    input clk,
    input reset,
	output d0);
reg  [11:0]  lfsr;
wire lfsr_equal;

xnor(d0,lfsr[9],lfsr[6]);
assign lfsr_equal = (lfsr ==12'hF8C);

always @(posedge clk,posedge reset) begin
    if(reset) begin
        lfsr <= 0;
    end
    else begin
          lfsr <= lfsr_equal ? 12'h0 : {lfsr[10:0],d0};
    end
end
endmodule
//End Copied Code