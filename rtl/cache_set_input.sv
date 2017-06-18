`timescale 1ns / 1ps
module cache_set_input
(
   clk,
   reset,

   valid_in,
   set_input_stage_valid,
   tag_compare_stage_ready,
   set_input_ready,
   
   start_great_x_in,
   start_x_ch,
   start_x_in,
   start_great_y_in,
   start_y_ch,
   start_y_in,
   
   rf_blk_hgt_in,
   rf_blk_wdt_in,   
   rf_blk_hgt_ch,   
   rf_blk_wdt_ch,   
   
   delta_x,
   delta_y,
   delta_x_luma,
   delta_x_chma,
   
   curr_x_addr,
   curr_y_addr,
   
   curr_x_luma,
   curr_y_luma,
   curr_x_chma,
   curr_y_chma,
   
   cur_xy_changed_luma,
   cur_xy_changed_chma, 
   
   // last_block_valid_0d
    curr_x,
    curr_y
);

    `include "../sim/cache_configs_def.v"
    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"

//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------

		localparam							    STATE_IDLE	 			= 0;
		localparam 							    STATE_ACTIVE 			= 1;
    parameter                           NUM_X_BANKS         = 1;
    parameter                           NUM_Y_BANKS         = 1;
      
    parameter                           LUMA_DIM_WDTH		    	= 4;        // out block dimension  max 11
    // parameter                           LUMA_DIM_ADDR_WDTH          = 7;        //max 121
    parameter                           CHMA_DIM_WDTH               = 3;        // max 5 (2+3) / (4+3)
    parameter                           CHMA_DIM_HIGT               = 3;        // max 5 (2+3) / (4+3)
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    

input                clk;
input                reset;

input                valid_in;
output reg           set_input_stage_valid;
input                tag_compare_stage_ready;
output reg           set_input_ready;

input     [X_ADDR_WDTH-1:0]                     start_great_x_in;
input     [X_ADDR_WDTH-1:0]                     start_great_y_in;
input     [X_ADDR_WDTH-1:0]                     start_x_in;
input     [Y_ADDR_WDTH-1:0]                     start_y_in;
input     [X_ADDR_WDTH-(C_SUB_WIDTH -1)-1:0]    start_x_ch; //% value after division by two
input     [Y_ADDR_WDTH-(C_SUB_HEIGHT-1)-1:0]    start_y_ch;

input     [LUMA_DIM_WDTH-1:0]                   rf_blk_hgt_in;
input     [LUMA_DIM_WDTH-1:0]                   rf_blk_wdt_in;
input     [CHMA_DIM_HIGT-1:0]                   rf_blk_hgt_ch;
input     [CHMA_DIM_WDTH-1:0]                   rf_blk_wdt_ch;   

input  [1:0]         delta_x;
input  [1:0]         delta_y;

input  [1:0]         delta_x_luma;
input  [1:0]         delta_x_chma;

output [X_ADDR_WDTH - C_L_H_SIZE -1: 0]         curr_x_addr;//[NUM_X_BANKS-1:0];
output [X_ADDR_WDTH - C_L_H_SIZE -1: 0]         curr_y_addr;//[NUM_Y_BANKS-1:0];

output reg     [1:0]                                   curr_x_luma;//[NUM_X_BANKS-1:0]; // possible 0,1,2
output reg     [1:0]                                   curr_y_luma;//[NUM_Y_BANKS-1:0]; // possible 0,1,2,3

output reg     [1:0]                                   curr_x_chma;//[NUM_X_BANKS-1:0]; // possible 0,1,2
output reg     [1:0]                                   curr_y_chma;//[NUM_Y_BANKS-1:0]; // possible 0,1,2,3

output reg           cur_xy_changed_luma;//[NUM_X_BANKS+NUM_Y_BANKS-2:0];
output reg           cur_xy_changed_chma;//[NUM_X_BANKS+NUM_Y_BANKS-2:0];

// output reg           last_block_valid_0d;
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------
reg [0:0]   state_set_input;
reg [0:0]   nxt_state_set_input;


output reg     [1:0]                            curr_x; // possible 0,1,2
output reg     [1:0]                            curr_y; // possible 0,1,2,3


reg     [1:0]                                   next_curr_x_luma; // possible 0,1,2
reg     [1:0]                                   next_curr_y_luma; // possible 0,1,2,3

reg     [1:0]                                   next_curr_x_chma; // possible 0,1,2
reg     [1:0]                                   next_curr_y_chma; // possible 0,1,2,3

reg     [1:0]                                   next_curr_x; // possible 0,1,2
reg     [1:0]                                   next_curr_y; // possible 0,1,2,3

wire                luma_dest_enable_wire_next;
wire                chma_dest_enable_wire_next;

//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------



 cache_dest_enable
 #(
   .START_X_WDTH  (X_ADDR_WDTH-(C_SUB_WIDTH -1)),
   .START_Y_WDTH  (Y_ADDR_WDTH-(C_SUB_HEIGHT-1)),
   .XXMA_DIM_WDTH (CHMA_DIM_WDTH),
   .XXMA_DIM_HIGT (CHMA_DIM_HIGT),
   .SHIFT_H       (C_L_H_SIZE_C),
   .SHIFT_V       (C_L_V_SIZE_C)
 )
 chma_dest_en_new
(
   .x_addr      (curr_x_addr          ),
   .y_addr      (curr_y_addr          ),
   .start_x     (start_x_ch                ),
   .start_y     (start_y_ch                ),
   .blk_width   (rf_blk_wdt_ch             ),
   .blk_height  (rf_blk_hgt_ch             ),
   .dest_enable (chma_dest_enable_wire_next)
);

 cache_dest_enable
 #(
   .NOW_X_WDTH    (X_ADDR_WDTH - C_L_H_SIZE),
   .NOW_Y_WDTH    (Y_ADDR_WDTH - C_L_V_SIZE),
   .START_X_WDTH  (X_ADDR_WDTH),
   .START_Y_WDTH  (Y_ADDR_WDTH),
   .XXMA_DIM_WDTH (LUMA_DIM_WDTH),
   .XXMA_DIM_HIGT (LUMA_DIM_WDTH),
   .SHIFT_H       (C_L_H_SIZE),
   .SHIFT_V       (C_L_V_SIZE)
 )
 luma_dest_en_new
(
   .x_addr      (curr_x_addr          ),
   .y_addr      (curr_y_addr          ),
   .start_x     (start_x_in                ),
   .start_y     (start_y_in                ),
   .blk_width   (rf_blk_wdt_in             ),
   .blk_height  (rf_blk_hgt_in             ),
   .dest_enable (luma_dest_enable_wire_next)
);

assign curr_x_addr = curr_x + (start_great_x_in >> C_L_H_SIZE); 
assign curr_y_addr = curr_y + (start_great_y_in >> C_L_V_SIZE);


// always@(*) begin
   // if(curr_x == delta_x && curr_y == delta_y) begin
      // last_block_valid_0d = 1;
   // end
   // else begin
      // last_block_valid_0d = 0;
   // end
// end 

always@(*) begin
      if(curr_x == delta_x) begin
        next_curr_x = 0;
        next_curr_y = curr_y + 1'b1;
      end
      else begin
        next_curr_x = curr_x + 1'b1;
        next_curr_y = curr_y;
      end   
end

always@(*) begin :next_curr_x_y

    if(curr_x_luma == delta_x_luma) begin
        next_curr_x_luma = 0;
        next_curr_y_luma = curr_y_luma + 1'b1;
    end
    else begin
        next_curr_x_luma = curr_x_luma + 1'b1;
        next_curr_y_luma = curr_y_luma;
    end	
    if(curr_x_chma == delta_x_chma) begin
        next_curr_x_chma = 0;
        next_curr_y_chma = curr_y_chma + 1'b1;
    end
    else begin
        next_curr_x_chma = curr_x_chma + 1'b1;
        next_curr_y_chma = curr_y_chma;
    end	
end

always@(*) begin
   nxt_state_set_input = state_set_input;
   set_input_ready = 0;
   case(state_set_input)
      STATE_IDLE: begin
         if(valid_in) begin
            nxt_state_set_input = STATE_ACTIVE;
         end
         set_input_ready = 1;
      end
      STATE_ACTIVE: begin
         if(tag_compare_stage_ready) begin
            if(curr_x == delta_x && curr_y == delta_y) begin
               nxt_state_set_input = STATE_IDLE;
            end
            else begin
               if(next_curr_x == delta_x && next_curr_y == delta_y) begin
                  nxt_state_set_input = STATE_IDLE;
               end            
            end
         end
      end
   endcase
end

always@(posedge clk) begin
   if(reset) begin
      state_set_input <= STATE_IDLE;
   end
   else begin
      state_set_input <= nxt_state_set_input;
   end
end
	
always@(posedge clk) begin : SET_INPUT_STAGE
	if(reset) begin
		set_input_stage_valid <= 0;
		curr_x <= 0;
      curr_y <= 0;
	end
	else begin
			case(state_set_input)
				STATE_IDLE: begin
               if(~( ~tag_compare_stage_ready)) begin
                  if(valid_in) begin
                     set_input_stage_valid <= 1;
                     curr_x <= 0;
                     curr_y <= 0;
                     curr_x_luma <= 0;
                     curr_y_luma <= 0;
                     curr_x_chma <= 0;
                     curr_y_chma <= 0;
                     cur_xy_changed_luma <= 1;
                     cur_xy_changed_chma <= 1;
                  end
                  else begin
                     set_input_stage_valid <= 0;
                  end
               end
				end
				STATE_ACTIVE: begin
               if(tag_compare_stage_ready) begin
                  if(curr_x == delta_x && curr_y == delta_y) begin
                     set_input_stage_valid <= 0;
                     if(delta_x == 0 && delta_y ==0) begin
                     end
                     else begin
                        $display("cache current x,y state trn. not next_x,y");
                        $stop;
                     end
                  end	
                  else begin
                     set_input_stage_valid <= 1; 
                     curr_x <= next_curr_x;
                     curr_y <= next_curr_y;
                     if(luma_dest_enable_wire_next) begin
                        curr_x_luma <= next_curr_x_luma;
                        curr_y_luma <= next_curr_y_luma;
                        cur_xy_changed_luma <= 1;
                     end
                     else begin
                        cur_xy_changed_luma <= 0;
                     end
                     if(chma_dest_enable_wire_next) begin
                        curr_x_chma <= next_curr_x_chma;
                        curr_y_chma <= next_curr_y_chma;
                        cur_xy_changed_chma <= 1;  
                     end
                     else begin
                        cur_xy_changed_chma <= 0;
                     end		
                                
                  end
               end
				end

			endcase
	end
end

endmodule