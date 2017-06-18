`timescale 1ns / 1ps
module num_val_clines_generator
(
		start_x_in,
		start_y_in,
		rf_blk_wdt_in,
		rf_blk_hgt_in,
		delta_x_out,
		delta_y_out
    );
	
	
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
    /* STYLE_NOTES :
     * Always include global constant header files that have constant definitions before all other items
     * these files will contain constants in the form of localparams of `define directives
     */
    `include "../sim/pred_def.v"     
    `include "../sim/cache_configs_def.v"

//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
    parameter                           DIM_WDTH		    	= 4;        // out block dimension    
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
 
	input [C_L_H_SIZE + DIM_WDTH-1:0] 		start_x_in;
	input [C_L_V_SIZE + DIM_WDTH-1:0] 		start_y_in;
	input [DIM_WDTH-1:0] 		rf_blk_wdt_in;	// max 11
	input [DIM_WDTH-1:0] 		rf_blk_hgt_in;
	 

	output [1:0]	delta_x_out;		// 0,1,2
	output [1:0] 	delta_y_out;		// 0,1,2,3
	
    wire [C_L_H_SIZE + DIM_WDTH-1:0] end_x ;
    wire [C_L_V_SIZE + DIM_WDTH-1:0] end_y ;

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------
    assign end_x = start_x_in+rf_blk_wdt_in;
    assign end_y = start_y_in+rf_blk_hgt_in;
    
	//always@* begin
	assign	delta_x_out = (end_x[C_L_H_SIZE +1:C_L_H_SIZE]) - (start_x_in[C_L_H_SIZE +1:C_L_H_SIZE]);
	assign	delta_y_out = (end_y[C_L_V_SIZE +1:C_L_V_SIZE]) - (start_y_in[C_L_V_SIZE +1:C_L_V_SIZE]);
	//end
	

endmodule