`timescale 1ns / 1ps
module tag_read_stage
(
   clk,
   reset,

   dest_enable_wire_valid,
   set_input_stage_valid,
   tag_compare_stage_ready_d,
   last_block_valid_1d,
   last_block_valid_0d,
   
   ref_idx_in,
   curr_x,
   curr_y,   
      
   delta_x,   
   delta_y,   
   
   curr_x_d,
   curr_y_d,   
      
   delta_x_d,   
   delta_y_d,     
   
   curr_x_addr,
   curr_y_addr,
   curr_x_luma,
   curr_y_luma,
   curr_x_chma,
   curr_y_chma,
   cur_xy_changed_luma,
   cur_xy_changed_chma,
   
   
   d_block_x_offset_luma,
   d_block_y_offset_luma,   
   d_block_x_offset_chma,   
   d_block_y_offset_chma, 
   
   rf_blk_hgt_in,
   rf_blk_wdt_in,   
   rf_blk_hgt_ch,   
   rf_blk_wdt_ch,   
   
   delta_x_luma,
   delta_y_luma,   
   delta_x_chma,   
   delta_y_chma,   
      
   start_x_in,
   start_y_in,
   start_x_ch,
   start_y_ch,
   
   curr_x_addr_reg,
   curr_y_addr_reg,
   set_addr,
   set_addr_d,
   tag_addr,
   
   rf_blk_hgt_in_d,
   rf_blk_wdt_in_d,
   rf_blk_hgt_ch_d,
   rf_blk_wdt_ch_d,
   
   start_x_in_d,
   start_y_in_d,
   start_x_ch_d,
   start_y_ch_d,
   
   ref_idx_in_d,
   cl_strt_x_luma_d,
   cl_strt_y_luma_d,
   cl_strt_x_chma_d,
   cl_strt_y_chma_d,
   
   
   dest_end_x_luma,
   dst_strt_x_luma,
   dest_end_y_luma,
   dst_strt_y_luma,
   
   dest_end_x_chma,
   dst_strt_x_chma,
   dest_end_y_chma,
   dst_strt_y_chma
   
    
);

    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"
    `include "../sim/cache_configs_def.v"

//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
   input                                            clk;
   input                                            reset;
   input    [1:0]                                   curr_x_luma; // possible 0,1,2
   input    [1:0]                                   curr_y_luma; // possible 0,1,2,3

   input    [1:0]                                   curr_x_chma; // possible 0,1,2
   input    [1:0]                                   curr_y_chma; // possible 0,1,2,3
   
   input    [1:0]                                   curr_x;
   input    [1:0]                                   curr_y;
   
   input    [1:0]                                   delta_x;
   input    [1:0]                                   delta_y;
   
   input                                            cur_xy_changed_luma;
   input                                            cur_xy_changed_chma; 

   input      [X_ADDR_WDTH-1:0]                     start_x_in;
   input      [Y_ADDR_WDTH-1:0]                     start_y_in;
   input      [X_ADDR_WDTH-(C_SUB_WIDTH -1)-1:0]    start_x_ch; //% value after division by two
   input      [Y_ADDR_WDTH-(C_SUB_HEIGHT-1)-1:0]    start_y_ch;
   
   input      [X_ADDR_WDTH - C_L_H_SIZE -1: 0]      curr_x_addr;
   input      [Y_ADDR_WDTH - C_L_V_SIZE -1: 0]      curr_y_addr;
   input      [REF_ADDR_WDTH-1:0]                   ref_idx_in;
   
   input      [LUMA_DIM_WDTH-1:0]                   d_block_x_offset_luma;  // starting position as an offset from top left corner
   input      [LUMA_DIM_WDTH-1:0]                   d_block_y_offset_luma;
   input      [CHMA_DIM_WDTH-1:0]                   d_block_x_offset_chma;
   input      [CHMA_DIM_HIGT-1:0]                   d_block_y_offset_chma; 
                                                    
   input      [LUMA_DIM_WDTH-1:0]                   rf_blk_hgt_in;
   input      [LUMA_DIM_WDTH-1:0]                   rf_blk_wdt_in;
   input      [CHMA_DIM_HIGT-1:0]                   rf_blk_hgt_ch;
   input      [CHMA_DIM_WDTH-1:0]                   rf_blk_wdt_ch;  
   
   input    [1:0]                                   delta_x_luma;    // possible 0,1,2
   input    [1:0]                                   delta_y_luma;    //possible 0,1,2,3   
   input    [1:0]                                   delta_x_chma; // possible 0,1,2
   input    [1:0]                                   delta_y_chma; //possible 0,1,2,3
   
   input       set_input_stage_valid;
   input       last_block_valid_0d;
   output reg  dest_enable_wire_valid;
   input       tag_compare_stage_ready_d;
   output reg  last_block_valid_1d;

   output reg  [LUMA_DIM_WDTH-1:0] dst_strt_x_luma;
   output reg  [LUMA_DIM_WDTH-1:0] dest_end_x_luma;
   output reg  [LUMA_DIM_WDTH-1:0] dst_strt_y_luma;
   output reg  [LUMA_DIM_WDTH-1:0] dest_end_y_luma;
   
   output reg  [CHMA_DIM_WDTH-1:0] dst_strt_x_chma;
   output reg  [CHMA_DIM_WDTH-1:0] dest_end_x_chma;
   output reg  [CHMA_DIM_HIGT-1:0] dst_strt_y_chma;
   output reg  [CHMA_DIM_HIGT-1:0] dest_end_y_chma;
   
   output reg  [LUMA_DIM_WDTH-1:0]                 rf_blk_hgt_in_d;
   output reg  [LUMA_DIM_WDTH-1:0]                 rf_blk_wdt_in_d;
   output reg  [CHMA_DIM_HIGT-1:0]                 rf_blk_hgt_ch_d;
   output reg  [CHMA_DIM_WDTH-1:0]                 rf_blk_wdt_ch_d;   
   
   output reg  [TAG_ADDR_WDTH-1:0]                   tag_addr;

   output reg    [C_L_H_SIZE-1:0]                    cl_strt_x_luma_d;
   output reg    [C_L_H_SIZE-1:0]                    cl_strt_y_luma_d;
   
   output reg    [C_L_H_SIZE_C-1:0]                  cl_strt_x_chma_d;   
   output reg    [C_L_V_SIZE_C-1:0]                  cl_strt_y_chma_d; 
   
   output reg  [X_ADDR_WDTH-1:0]                     start_x_in_d;
   output reg  [Y_ADDR_WDTH-1:0]                     start_y_in_d;
   output reg  [X_ADDR_WDTH-(C_SUB_WIDTH -1)-1:0]    start_x_ch_d; //% value after division by two
   output reg  [Y_ADDR_WDTH-(C_SUB_HEIGHT-1)-1:0]    start_y_ch_d;
   
   output reg     [X_ADDR_WDTH - C_L_H_SIZE -1: 0]    curr_x_addr_reg;
   output reg     [Y_ADDR_WDTH - C_L_V_SIZE -1: 0]    curr_y_addr_reg;
   
   output reg    [1:0]                                   curr_x_d;
   output reg    [1:0]                                   curr_y_d;
   output reg    [1:0]                                   delta_x_d;
   output reg    [1:0]                                   delta_y_d;
   
   output reg     [SET_ADDR_WDTH -1:0]             set_addr;
   output reg     [SET_ADDR_WDTH -1:0]             set_addr_d;

   output reg     [REF_ADDR_WDTH-1:0]                 ref_idx_in_d;
   
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

   wire    [C_L_H_SIZE-1:0]                        cl_strt_x_luma;
   wire    [C_L_H_SIZE-1:0]                        cl_strt_y_luma;

   wire    [C_L_H_SIZE_C-1:0]                      cl_strt_x_chma;   
   wire    [C_L_V_SIZE_C-1:0]                      cl_strt_y_chma;   


   reg     [CHMA_DIM_WDTH-1:0] next_dst_strt_x_chma;
   reg     [CHMA_DIM_WDTH-1:0] next_dest_end_x_chma;
   reg     [CHMA_DIM_HIGT-1:0] next_dst_strt_y_chma;
   reg     [CHMA_DIM_HIGT-1:0] next_dest_end_y_chma;
   

   reg     [LUMA_DIM_WDTH-1:0] next_dst_strt_x_luma;
   reg     [LUMA_DIM_WDTH-1:0] next_dest_end_x_luma;
   reg     [LUMA_DIM_WDTH-1:0] next_dst_strt_y_luma;
   reg     [LUMA_DIM_WDTH-1:0] next_dest_end_y_luma;
   
   
//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

assign cl_strt_x_luma    = (curr_x_luma == 2'b00)                ? start_x_in[C_L_H_SIZE-1:0]                                : {C_L_H_SIZE{1'b0}};
//assign cl_end__x_luma    = (curr_x_luma == delta_x_luma)         ? start_x_in[C_L_H_SIZE-1:0] + rf_blk_wdt_in[C_L_H_SIZE-1:0]: {C_L_H_SIZE{1'b1}};

assign cl_strt_y_luma    = (curr_y_luma == 2'b00)                ? start_y_in[C_L_V_SIZE-1:0]                                : {C_L_V_SIZE{1'b0}};
//assign cl_end__y_luma    = (curr_y_luma == delta_y_luma)         ? start_y_in[C_L_H_SIZE-1:0] + rf_blk_hgt_in[C_L_H_SIZE-1:0]: {C_L_H_SIZE{1'b1}};

assign cl_strt_x_chma    = (curr_x_chma == 0)                   ? start_x_ch[C_L_H_SIZE_C-1:0]                                  : {C_L_H_SIZE_C{1'b0}};
//assign cl_end__x_chma    = (curr_x_chma == delta_x_chma)        ? start_x_ch[C_L_H_SIZE_C-1:0] + rf_blk_wdt_ch[C_L_H_SIZE_C-1:0]: {C_L_H_SIZE_C{1'b1}};

assign cl_strt_y_chma    = (curr_y_chma == 0)                   ? start_y_ch[C_L_V_SIZE_C-1:0]                                  : {C_L_V_SIZE_C{1'b0}};
//assign cl_end__y_chma    = (curr_y_chma == delta_y_chma)        ? start_y_ch[C_L_H_SIZE_C-1:0] + rf_blk_hgt_ch[C_L_H_SIZE_C-1:0]: {C_L_H_SIZE_C{1'b1}};
 		

    

always@(*) begin : next_dest_start_end
    if(curr_x_chma == 0) begin
        next_dst_strt_x_chma = d_block_x_offset_chma;
        if(curr_x_chma == delta_x_chma) begin
            next_dest_end_x_chma = d_block_x_offset_chma + rf_blk_wdt_ch;
        end
        else begin
            next_dest_end_x_chma = {1'b0,({C_L_H_SIZE_C{1'b1}} - start_x_ch[C_L_H_SIZE_C-1:0])} + d_block_x_offset_chma;
        end
    end
    else begin
        next_dst_strt_x_chma = dest_end_x_chma + 1'b1;   // max 4
        if(curr_x_chma == delta_x_chma) begin
            next_dest_end_x_chma = d_block_x_offset_chma + rf_blk_wdt_ch;
        end
        else begin
            next_dest_end_x_chma = dest_end_x_chma + {1'b1,{C_L_H_SIZE_C{1'b0}}};
        end
    end
    if(curr_x_luma == 0) begin
        next_dst_strt_x_luma = d_block_x_offset_luma;
        if(curr_x_luma == delta_x_luma) begin
            next_dest_end_x_luma = d_block_x_offset_luma + rf_blk_wdt_in;
        end
        else begin
            next_dest_end_x_luma = {1'b0,({C_L_H_SIZE{1'b1}} - start_x_in[C_L_H_SIZE-1:0])} + d_block_x_offset_luma;
        end
    end
    else begin
        next_dst_strt_x_luma = dest_end_x_luma + 1'b1;
        if(curr_x_luma == delta_x_luma) begin
            next_dest_end_x_luma = d_block_x_offset_luma + rf_blk_wdt_in;
        end
        else begin
            next_dest_end_x_luma = dest_end_x_luma + {1'b1,{C_L_H_SIZE{1'b0}}}; 
        end
    end
    if(curr_y_chma == 0) begin
        next_dst_strt_y_chma = d_block_y_offset_chma;
        if(curr_y_chma == delta_y_chma) begin
            next_dest_end_y_chma = d_block_y_offset_chma + rf_blk_hgt_ch;
        end
        else begin
            next_dest_end_y_chma = {1'b0,({C_L_V_SIZE_C{1'b1}} - start_y_ch[C_L_V_SIZE_C-1:0])} + d_block_y_offset_chma;
        end
    end
    else if(curr_x_chma == 0)begin
        next_dst_strt_y_chma = dest_end_y_chma + 1'b1;  
        if(curr_y_chma == delta_y_chma) begin
            next_dest_end_y_chma = d_block_y_offset_chma + rf_blk_hgt_ch;
        end
        else begin 
            next_dest_end_y_chma = dest_end_y_chma + {1'b1,{C_L_V_SIZE_C{1'b0}}};
        end
    end
    else begin
        next_dst_strt_y_chma = dst_strt_y_chma;
        next_dest_end_y_chma = dest_end_y_chma;        
    end
    if(curr_y_luma == 0) begin
        next_dst_strt_y_luma = d_block_y_offset_luma;
        if(curr_y_luma == delta_y_luma) begin
            next_dest_end_y_luma = d_block_y_offset_luma + rf_blk_hgt_in;
        end
        else begin
            next_dest_end_y_luma = {1'b0,({C_L_V_SIZE{1'b1}} - start_y_in[C_L_V_SIZE-1:0])} + d_block_y_offset_luma;
        end
    end
    else if(curr_x_luma == 0)begin
        next_dst_strt_y_luma = dest_end_y_luma + 1'b1;
        if(curr_y_luma == delta_y_luma) begin
            next_dest_end_y_luma = d_block_y_offset_luma + rf_blk_hgt_in;
        end
        else begin
            next_dest_end_y_luma = dest_end_y_luma + {1'b1,{C_L_V_SIZE{1'b0}}}; 
        end
    end
    else begin
        next_dst_strt_y_luma = dst_strt_y_luma;
        next_dest_end_y_luma = dest_end_y_luma;
    end
end

	
always@(posedge clk) begin : TAG_READ_STATE
	if(reset) begin
		dest_enable_wire_valid <= 0;
		curr_x_addr_reg     <= 0;		// reseting to set valid value for araddr after reset
		curr_y_addr_reg     <= 0;
		last_block_valid_1d <= 0;
	end
	else begin
            if(tag_compare_stage_ready_d) begin
               if(set_input_stage_valid ) begin 
                  dest_enable_wire_valid <= 1;
                  last_block_valid_1d <= last_block_valid_0d;

                  curr_x_addr_reg     <= curr_x_addr;
                  curr_y_addr_reg     <= curr_y_addr;
                  tag_addr <= {ref_idx_in,curr_y_addr[Y_ADDR_WDTH - C_L_V_SIZE -1:SET_ADDR_Y_WIDTH],curr_x_addr[X_ADDR_WDTH-C_L_H_SIZE-1:SET_ADDR_X_WIDTH]};    // the 2 in the expression indicates x/y bits in the set address        
                  set_addr_d <= set_addr;
                  
                  rf_blk_hgt_in_d  <= rf_blk_hgt_in;  
                  rf_blk_wdt_in_d  <= rf_blk_wdt_in;
                  rf_blk_hgt_ch_d  <= rf_blk_hgt_ch;
                  rf_blk_wdt_ch_d  <= rf_blk_wdt_ch;
                  
                  start_x_in_d <= start_x_in;
                  start_y_in_d <= start_y_in;
                  start_x_ch_d <= start_x_ch;
                  start_y_ch_d <= start_y_ch;
                  
                  curr_x_d  <= curr_x;
                  curr_y_d  <= curr_y;
                  delta_x_d  <= delta_x;
                  delta_y_d  <= delta_y;
                  
                  ref_idx_in_d <= ref_idx_in;

                  if(cur_xy_changed_luma) begin
                     cl_strt_x_luma_d <= cl_strt_x_luma;
                     //cl_end__x_luma_d <= cl_end__x_luma;
                     cl_strt_y_luma_d <= cl_strt_y_luma;
                     //cl_end__y_luma_d <= cl_end__y_luma;

                     dest_end_x_luma <= next_dest_end_x_luma;
                     dst_strt_x_luma <= next_dst_strt_x_luma;
                     dest_end_y_luma <= next_dest_end_y_luma;
                     dst_strt_y_luma <= next_dst_strt_y_luma;
                  end
                  if(cur_xy_changed_chma) begin
                     cl_strt_x_chma_d <= cl_strt_x_chma;
                     //cl_end__x_chma_d <= cl_end__x_chma;
                     cl_strt_y_chma_d <= cl_strt_y_chma;
                     //cl_end__y_chma_d <= cl_end__y_chma;

                     dest_end_x_chma <= next_dest_end_x_chma;
                     dst_strt_x_chma <= next_dst_strt_x_chma;
                     dest_end_y_chma <= next_dest_end_y_chma;
                     dst_strt_y_chma <= next_dst_strt_y_chma;
                  end					
               end
               else begin
                  dest_enable_wire_valid <= 0;
               end
            end
	end
end


always@(*) begin
	set_addr = {curr_y_addr[SET_ADDR_X_WIDTH-1:0],curr_x_addr[SET_ADDR_X_WIDTH-1:0]};
end



endmodule