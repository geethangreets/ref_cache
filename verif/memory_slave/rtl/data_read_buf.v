`timescale 1ns / 1ps

module data_read_buf
    (
      clk,
      reset,

      rid,
      rdata,
      rresp,
      rlast,
      rvalid,
      rready,


      rid_in,
      rdata_in,
      rresp_in,
      rlast_in,
      rvalid_in

    );

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
   `include "../sim/param.v"
   `include "../sim/pred_def.v"
   
//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
`ifdef MORE_DDR_READ_DELAY
	parameter DELAY_LEVELS = 40;
`else 
	parameter DELAY_LEVELS = 1;
`endif
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    input clk;
    input reset;

    output reg[ADD_ID_WIDTH-1:0]rid;
    output reg[DATA_WIDTH-1:0]rdata;
    output reg[1:0]rresp;
    output reg rlast;
    output reg rvalid;
    input rready;


    input [ADD_ID_WIDTH-1:0]rid_in;
    input [DATA_WIDTH-1:0]rdata_in;
    input [1:0]rresp_in;
    input  rlast_in;
    input  rvalid_in;


//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

    reg[ADD_ID_WIDTH-1:0]rid_int[0:DELAY_LEVELS-1];
    reg[DATA_WIDTH-1:0]rdata_int[0:DELAY_LEVELS-1];
    reg[1:0]rresp_int[0:DELAY_LEVELS-1];
    reg rlast_int[0:DELAY_LEVELS-1];
    reg rvalid_int[0:DELAY_LEVELS-1];
	
	integer i;
	
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

always@(posedge clk) begin
	if(reset) begin
	end
	else begin
		if(rready) begin
			for(i=0;i<=DELAY_LEVELS; i=i+1) begin
				if(i==0) begin
					rid_int[i]		 <=rid_in	 ;
					rdata_int[i]     <=rdata_in  ;
					rresp_int[i]     <=rresp_in  ;
					rlast_int[i]     <=rlast_in  ;
					rvalid_int[i]    <=rvalid_in ;	
				end
				else if(i== DELAY_LEVELS) begin
					   rid		 <=rid_int[i-1]	 	;
					 rdata     <=rdata_int[i-1]  	;
					 rresp     <=rresp_int[i-1]  	;
					 rlast     <=rlast_int[i-1]  	;
					rvalid    <=rvalid_int[i-1] 	;					
				end
				else begin
					rid_int[i]		 <=rid_int[i-1]	 	;
					rdata_int[i]     <=rdata_int[i-1]  	;
					rresp_int[i]     <=rresp_int[i-1]  	;
					rlast_int[i]     <=rlast_int[i-1]  	;
					rvalid_int[i]    <=rvalid_int[i-1] 	;	
				end
		
			end
		  
		end	
	end
end

endmodule