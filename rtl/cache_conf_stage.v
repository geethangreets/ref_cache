`timescale 1ns / 1ps
module cache_conf_stage
(
   clk,
   reset,
   
   valid_in,
   tag_compare_stage_ready,
   op_conf_fifo_wr_en,
   
   pic_width,
   pic_height,
   
   xT_in_min_tus,
   yT_in_min_tus,
   ref_idx_in,
   ntbs_sh,
   res_present,
   bi_pred_block_cache,
   x0_tu_end_in_min_tus,
   y0_tu_end_in_min_tus,
   luma_ref_start_x,
   luma_ref_start_y,
   chma_ref_start_x,
   chma_ref_start_y,
   chma_ref_width_x,
   chma_ref_height_y,
   luma_ref_width_x,
   luma_ref_height_y,
   d_frac_x_out,
   d_frac_y_out,
   
   xT_in_min_tus_in,
   yT_in_min_tus_in,
   ref_idx_in_in,
   ntbs_sh_in,
   res_present_in,
   bi_pred_block_cache_in,
   x0_tu_end_in_min_tus_in,
   y0_tu_end_in_min_tus_in,
   luma_ref_start_x_in,
   luma_ref_start_y_in,
   chma_ref_start_x_in,
   chma_ref_start_y_in,
   chma_ref_width_x_in,
   chma_ref_height_y_in,
   luma_ref_width_x_in,
   luma_ref_height_y_in,
   ch_frac_x,
   ch_frac_y,   
   
   start_x_in,
   start_y_in,
   start_x_ch,
   start_y_ch,
   rf_blk_wdt_in,
   rf_blk_hgt_in,
   rf_blk_wdt_ch,
   rf_blk_hgt_ch,
   rf_blk_great_wdt_in,
   rf_blk_great_hgt_in,
   start_great_x_in,
   start_great_y_in,
   d_block_x_end_luma,
   d_block_y_end_luma,
   d_block_x_offset_luma,
   d_block_y_offset_luma,
   d_block_x_end_chma,
   d_block_y_end_chma,
   d_block_x_offset_chma,
   d_block_y_offset_chma 
   
   
);

    `include "../sim/cache_configs_def.v"
    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"

//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------
    parameter                           LUMA_DIM_WDTH		    	= 4;        // out block dimension  max 11
    parameter                           CHMA_DIM_WDTH               = 3;        // max 5 (2+3) / (4+3)
    parameter                           CHMA_DIM_HIGT               = 3;        // max 5 (2+3) / (4+3)
    
    parameter                           LUMA_REF_BLOCK_WIDTH        = 4'd11;
    parameter                           CHMA_REF_BLOCK_WIDTH        = (C_SUB_WIDTH  == 1) ? 3'd7: 3'd5;
    parameter                           CHMA_REF_BLOCK_HIGHT        = (C_SUB_HEIGHT == 1) ? 3'd7: 3'd5;
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------

   input clk;
   input reset;
   input valid_in;
   input tag_compare_stage_ready;
   
   input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   pic_width;   
   input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   pic_height;   

	output reg op_conf_fifo_wr_en;
   
   input   [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0]     xT_in_min_tus_in;
   input   [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0]     yT_in_min_tus_in;
   input	  [REF_ADDR_WDTH-1:0]                          ref_idx_in_in;
   
   input                                          res_present_in;
   input                                          bi_pred_block_cache_in;
   input [NTBS_SH_WDTH -1: 0]                     ntbs_sh_in;
   input [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0] x0_tu_end_in_min_tus_in;
   input [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0] y0_tu_end_in_min_tus_in;
   input [MV_C_FRAC_WIDTH_HIGH -1:0]              ch_frac_x;
   input [MV_C_FRAC_WIDTH_HIGH -1:0]              ch_frac_y;	
   
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_x_in;	
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_y_in;
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_x_in;	
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_y_in;	
	
	input  [LUMA_DIM_WDTH - 1:0]   			                  chma_ref_width_x_in            ;	
   input  [LUMA_DIM_WDTH - 1:0]                             chma_ref_height_y_in           ;   
	input  [LUMA_DIM_WDTH - 1:0]   			                  luma_ref_width_x_in            ;	
   input  [LUMA_DIM_WDTH - 1:0]                             luma_ref_height_y_in           ;  
   
   output reg [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0] xT_in_min_tus;
   output reg [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0] yT_in_min_tus;
    
   output reg         [REF_ADDR_WDTH-1:0]                 ref_idx_in;   
   output reg         [LUMA_DIM_WDTH-1:0]                 rf_blk_hgt_in;
   output reg         [LUMA_DIM_WDTH-1:0]                 rf_blk_wdt_in;
   output reg         [CHMA_DIM_HIGT-1:0]                 rf_blk_hgt_ch;
   output reg         [CHMA_DIM_WDTH-1:0]                 rf_blk_wdt_ch; 
   
   output reg       [X_ADDR_WDTH-1:0]                     start_great_x_in;
   output reg       [Y_ADDR_WDTH-1:0]                     start_great_y_in;
   output reg       [LUMA_DIM_WDTH-1:0]                   rf_blk_great_hgt_in;
   output reg       [LUMA_DIM_WDTH-1:0]                   rf_blk_great_wdt_in;  
   
   output reg       [X_ADDR_WDTH-1:0]                     start_x_in;
   output reg       [Y_ADDR_WDTH-1:0]                     start_y_in;
   output reg       [X_ADDR_WDTH-(C_SUB_WIDTH -1)-1:0]    start_x_ch; //% value after division by two
   output reg       [Y_ADDR_WDTH-(C_SUB_HEIGHT-1)-1:0]    start_y_ch;

   output reg        [LUMA_DIM_WDTH-1:0]                 d_block_x_offset_luma;  // starting position as an offset from top left corner
   output reg        [LUMA_DIM_WDTH-1:0]                 d_block_y_offset_luma;
   output reg        [CHMA_DIM_WDTH-1:0]                 d_block_x_offset_chma;
   output reg        [CHMA_DIM_HIGT-1:0]                 d_block_y_offset_chma; 

   output reg        [LUMA_DIM_WDTH-1:0]                 d_block_x_end_luma;
   output reg        [LUMA_DIM_WDTH-1:0]                 d_block_y_end_luma;
   output reg        [CHMA_DIM_WDTH-1:0]                 d_block_x_end_chma;
   output reg        [CHMA_DIM_HIGT-1:0]                 d_block_y_end_chma;    
   

   output reg        [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  luma_ref_start_x  ;
   output reg        [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  luma_ref_start_y  ;
   output reg        [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  chma_ref_start_x  ;
   output reg        [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  chma_ref_start_y  ;
   
   output reg         [LUMA_DIM_WDTH - 1:0]                   chma_ref_width_x;
   output reg         [LUMA_DIM_WDTH - 1:0]                   chma_ref_height_y;
   output reg         [LUMA_DIM_WDTH - 1:0]                   luma_ref_width_x;
   output reg         [LUMA_DIM_WDTH - 1:0]                   luma_ref_height_y;
   
   output reg                                          res_present;
   output reg                                          bi_pred_block_cache;
   output reg [NTBS_SH_WDTH -1: 0]                     ntbs_sh;
   output reg [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0] x0_tu_end_in_min_tus;
   output reg [X11_ADDR_WDTH - LOG2_MIN_TU_SIZE - 1:0] y0_tu_end_in_min_tus;
   output reg  [MV_C_FRAC_WIDTH_HIGH -1:0]             d_frac_x_out;
   output reg  [MV_C_FRAC_WIDTH_HIGH -1:0]             d_frac_y_out;	

   
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   luma_ref_end_x             ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   luma_ref_end_y             ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   chma_ref_end_x             ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   chma_ref_end_y             ;  
   
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   luma_start_x_rel_pic_width ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   luma_start_y_rel_pic_height;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   chma_start_x_rel_pic_width ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   chma_start_y_rel_pic_height; 
   
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   luma_start_x_rel_0         ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   luma_start_y_rel_0         ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   chma_start_x_rel_0         ;
   wire  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   chma_start_y_rel_0         ;
   
//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

   assign   luma_ref_end_x              = luma_ref_start_x_in + luma_ref_width_x_in  ;   
   assign   luma_ref_end_y              = luma_ref_start_y_in + luma_ref_height_y_in ;
   assign   chma_ref_end_x              = chma_ref_start_x_in + chma_ref_width_x_in;   
   assign   chma_ref_end_y              = chma_ref_start_y_in + chma_ref_height_y_in ;	
   
   assign   luma_start_x_rel_pic_width  =  pic_width  - 1'b1 -     luma_ref_start_x_in;   
   assign   luma_start_y_rel_pic_height =  pic_height - 1'b1 -     luma_ref_start_y_in;
   assign   chma_start_x_rel_pic_width  =  pic_width  - 1'b1 -     chma_ref_start_x_in;  
   assign   chma_start_y_rel_pic_height =  pic_height - 1'b1 -     chma_ref_start_y_in; 
   
   assign   luma_start_x_rel_0          =  0  -       luma_ref_start_x_in;   
   assign   luma_start_y_rel_0          =  0  -       luma_ref_start_y_in;
   assign   chma_start_x_rel_0          =  0  -       chma_ref_start_x_in;  
   assign   chma_start_y_rel_0          =  0  -       chma_ref_start_y_in; 
  
   
always@(posedge clk) begin : SET_CONFIG
	if(reset) begin
		ref_idx_in <= 0;
      op_conf_fifo_wr_en <= 1'b0;
	end
	else begin
      op_conf_fifo_wr_en <= 0;
      if(~( ~tag_compare_stage_ready)) begin
         if(valid_in) begin
            op_conf_fifo_wr_en <= 1;
            xT_in_min_tus <= xT_in_min_tus_in;
            yT_in_min_tus <= yT_in_min_tus_in;
            ntbs_sh  <= ntbs_sh_in;
            
            res_present <= res_present_in;
            bi_pred_block_cache <= bi_pred_block_cache_in;
            x0_tu_end_in_min_tus <= x0_tu_end_in_min_tus_in;
            y0_tu_end_in_min_tus <= y0_tu_end_in_min_tus_in;

            luma_ref_start_x    <=  luma_ref_start_x_in  ;
            luma_ref_start_y    <=  luma_ref_start_y_in  ;   
            chma_ref_start_x    <=  chma_ref_start_x_in >>>(C_SUB_WIDTH -1) ;       
            chma_ref_start_y    <=  chma_ref_start_y_in >>>(C_SUB_HEIGHT -1) ;       
            chma_ref_width_x    <=  chma_ref_width_x_in >>(C_SUB_WIDTH -1) ;   
            chma_ref_height_y   <=  chma_ref_height_y_in >>(C_SUB_HEIGHT -1);       
            luma_ref_width_x    <=  luma_ref_width_x_in  ;       
            luma_ref_height_y   <=  luma_ref_height_y_in ;   
            d_frac_x_out <= ch_frac_x;
            d_frac_y_out <= ch_frac_y;    
                  
            if(luma_ref_start_x_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               start_x_in <= 0;
            end
            else if(luma_ref_start_x_in >= pic_width)  begin
               start_x_in <= pic_width -1'b1;
            end
            else begin
               start_x_in <= luma_ref_start_x_in[X_ADDR_WDTH - 1:0];
            end

            if(luma_ref_start_y_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               start_y_in <= 0;
            end
            else if(luma_ref_start_y_in >= pic_height) begin
               start_y_in <= pic_height -1'b1;
            end
            else begin
               start_y_in <= luma_ref_start_y_in[X_ADDR_WDTH - 1:0];
            end

            if(chma_ref_start_x_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               start_x_ch <= 0;
            end
            else if(chma_ref_start_x_in >= pic_width) begin
               start_x_ch <= (pic_width>>(C_SUB_WIDTH -1))-1'b1;
            end
            else begin
               start_x_ch <= chma_ref_start_x_in[X_ADDR_WDTH - 1:0]>>(C_SUB_WIDTH -1);
            end

            if(chma_ref_start_y_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               start_y_ch <= 0;
            end
            else if(chma_ref_start_y_in >= pic_height) begin
               start_y_ch <= (pic_height>>(C_SUB_HEIGHT-1)) -1'b1;
            end
            else begin
               start_y_ch <= chma_ref_start_y_in[X_ADDR_WDTH - 1:0]>>(C_SUB_HEIGHT-1);
            end						
            if(ch_frac_x == 3'b100) begin
               if(chma_ref_start_x_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  start_great_x_in <= 0;
               end
               else if(chma_ref_start_x_in >= pic_width) begin
                  start_great_x_in <= pic_width -1'b1;
               end
               else begin
                  start_great_x_in <= chma_ref_start_x_in[X_ADDR_WDTH - 1:0];
               end
            end
            else begin
               if(luma_ref_start_x_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  start_great_x_in <= 0;
               end
               else if(luma_ref_start_x_in >= pic_width) begin
                  start_great_x_in <= pic_width -1;
               end
               else begin
                  start_great_x_in <= luma_ref_start_x_in[X_ADDR_WDTH - 1:0];
               end
            end
            
            if(ch_frac_y == 3'b100) begin
               if(chma_ref_start_y_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  start_great_y_in <= 0;
               end
               else if(chma_ref_start_y_in >= pic_height)begin
                  start_great_y_in <= pic_height -1;
               end
               else begin
                  start_great_y_in <= chma_ref_start_y_in[X_ADDR_WDTH - 1:0];
               end
            end
            else begin
               if(luma_ref_start_y_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  start_great_y_in <= 0;
               end
               else if(luma_ref_start_y_in >= pic_height) begin
                  start_great_y_in <= pic_height -1;
               end
               else begin
                  start_great_y_in <= luma_ref_start_y_in[X_ADDR_WDTH - 1:0];
               end
            end						
            //--------------------set luma width		
            if(luma_ref_start_x_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               d_block_x_end_luma <= LUMA_REF_BLOCK_WIDTH -1;
               if(luma_ref_end_x[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  d_block_x_offset_luma <= LUMA_REF_BLOCK_WIDTH -1;
                  
                  rf_blk_wdt_in <= 0;
                  if(ch_frac_x != 3'b100) begin
                     rf_blk_great_wdt_in <= 0;
                  end
               end
               else begin
                  if(ch_frac_x != 3'b100) begin
                     rf_blk_great_wdt_in <= luma_ref_end_x[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_wdt_in <= luma_ref_end_x[LUMA_DIM_WDTH-1:0];
                  d_block_x_offset_luma <= luma_start_x_rel_0[LUMA_DIM_WDTH-1:0];
               end
            end
            
            else if(luma_ref_end_x >= pic_width) begin
               d_block_x_offset_luma <= 0;
               if(luma_start_x_rel_pic_width[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] ==1) begin
                  if(ch_frac_x != 3'b100) begin
                     rf_blk_great_wdt_in <= 0;
                  end
                  rf_blk_wdt_in <= 0;
                  d_block_x_end_luma <= 0;
               end
               else begin
                  if(ch_frac_x != 3'b100) begin
                     rf_blk_great_wdt_in <= luma_start_x_rel_pic_width[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_wdt_in <= luma_start_x_rel_pic_width[LUMA_DIM_WDTH-1:0];    
                  d_block_x_end_luma <= luma_start_x_rel_pic_width[LUMA_DIM_WDTH-1:0];                      
               end
            end
            else begin
               if(ch_frac_x != 3'b100) begin
                  rf_blk_great_wdt_in <= luma_ref_width_x_in;
               end
               rf_blk_wdt_in <= luma_ref_width_x_in;
               d_block_x_offset_luma <= 0;
               d_block_x_end_luma <= luma_ref_width_x_in;
            end

            //--------------------set luma height
            if(luma_ref_start_y_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               d_block_y_end_luma <= LUMA_REF_BLOCK_WIDTH -1;
               if(luma_ref_end_y[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  rf_blk_hgt_in <= 0;
                  d_block_y_offset_luma <= LUMA_REF_BLOCK_WIDTH -1;
                  if(ch_frac_y != 3'b100) begin
                     rf_blk_great_hgt_in <= 0;
                  end
               end
               else begin
                  if(ch_frac_y != 3'b100) begin
                     rf_blk_great_hgt_in <= luma_ref_end_y[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_hgt_in <= luma_ref_end_y[LUMA_DIM_WDTH-1:0];
                  d_block_y_offset_luma <= luma_start_y_rel_0[LUMA_DIM_WDTH-1:0];
               end
            end

            else if(luma_ref_end_y >= pic_height) begin
               d_block_y_offset_luma <= 0;
               if(luma_start_y_rel_pic_height[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] ==1) begin
                  if(ch_frac_y != 3'b100) begin
                     rf_blk_great_hgt_in <= 0;
                  end
                  rf_blk_hgt_in <= 0;
                  d_block_y_end_luma <= 0;
               end
               else begin
                  if(ch_frac_y != 3'b100) begin
                     rf_blk_great_hgt_in <= luma_start_y_rel_pic_height[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_hgt_in <= luma_start_y_rel_pic_height[LUMA_DIM_WDTH-1:0];
                  d_block_y_end_luma <= luma_start_y_rel_pic_height[LUMA_DIM_WDTH-1:0];
               end
            end
            else begin
               if(ch_frac_y != 3'b100) begin
                  rf_blk_great_hgt_in <= luma_ref_height_y_in;
               end
               rf_blk_hgt_in <= luma_ref_height_y_in;
               d_block_y_offset_luma <= 0;
               d_block_y_end_luma <= luma_ref_height_y_in;
            end

            //--------------------set chma width
            if(chma_ref_start_x_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               d_block_x_end_chma <= CHMA_REF_BLOCK_WIDTH -1;
               if(chma_ref_end_x[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  d_block_x_offset_chma <= CHMA_REF_BLOCK_WIDTH -1;
                  rf_blk_wdt_ch <= 0;
                  if(ch_frac_x == 3'b100) begin
                     rf_blk_great_wdt_in <= 0;
                  end
               end
               else begin
                  if(ch_frac_x == 3'b100) begin
                     rf_blk_great_wdt_in <= chma_ref_end_x[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_wdt_ch <= chma_ref_end_x[LUMA_DIM_WDTH-1:0] >> (C_SUB_WIDTH-1);
                  d_block_x_offset_chma <= chma_start_x_rel_0[LUMA_DIM_WDTH-1:0] >> (C_SUB_WIDTH-1);
               end
            end
            else if(chma_ref_end_x >= pic_width) begin
               d_block_x_offset_chma <= 0;
               if(chma_start_x_rel_pic_width[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] ==1) begin
                  if(ch_frac_x == 3'b100) begin
                     rf_blk_great_wdt_in <= 0;
                  end
                  rf_blk_wdt_ch <= 0;
                  d_block_x_end_chma <= 0;
               end
               else begin
                  if(ch_frac_x == 3'b100) begin
                     rf_blk_great_wdt_in <= chma_start_x_rel_pic_width[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_wdt_ch <= chma_start_x_rel_pic_width[LUMA_DIM_WDTH-1:0] >> (C_SUB_WIDTH-1);
                  d_block_x_end_chma <= chma_start_x_rel_pic_width[LUMA_DIM_WDTH-1:0] >> (C_SUB_WIDTH-1);
               end
            end
            else begin
               if(ch_frac_x == 3'b100) begin
                  rf_blk_great_wdt_in <= chma_ref_width_x_in;
               end
               rf_blk_wdt_ch <= chma_ref_width_x_in >> (C_SUB_WIDTH-1);
               d_block_x_offset_chma <= 0;
               d_block_x_end_chma <= chma_ref_width_x_in >> (C_SUB_WIDTH-1);
            end
            
            //--------------------set chma height
            if(chma_ref_start_y_in[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
               d_block_y_end_chma <= CHMA_REF_BLOCK_WIDTH -1;
               if(chma_ref_end_y[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] == 1) begin
                  d_block_y_offset_chma <= CHMA_REF_BLOCK_HIGHT -1;
                  rf_blk_hgt_ch <= 0;
                  if(ch_frac_y == 3'b100) begin
                     rf_blk_great_hgt_in <= 0;
                  end
               end
               else begin
                  if(ch_frac_y == 3'b100) begin
                     rf_blk_great_hgt_in <= chma_ref_end_y[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_hgt_ch <= chma_ref_end_y[LUMA_DIM_WDTH-1:0] >> (C_SUB_HEIGHT-1);
                  d_block_y_offset_chma <= chma_start_y_rel_0[LUMA_DIM_WDTH-1:0] >> (C_SUB_HEIGHT-1);
               end
            end
            else if(chma_ref_end_y >= pic_height) begin
               d_block_y_offset_chma <= 0;
               if(chma_start_y_rel_pic_height[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1] ==1) begin
                  if(ch_frac_y == 3'b100) begin
                     rf_blk_great_hgt_in <= 0;
                  end
                  rf_blk_hgt_ch <= 0;
                  d_block_y_end_chma <= 0;
               end
               else begin
                  if(ch_frac_y == 3'b100) begin
                     rf_blk_great_hgt_in <= chma_start_y_rel_pic_height[LUMA_DIM_WDTH-1:0];
                  end
                  rf_blk_hgt_ch <= chma_start_y_rel_pic_height[LUMA_DIM_WDTH-1:0] >> (C_SUB_HEIGHT-1);
                  d_block_y_end_chma <= chma_start_y_rel_pic_height[LUMA_DIM_WDTH-1:0] >> (C_SUB_HEIGHT-1);
               end
            end
            else begin
               if(ch_frac_y == 3'b100) begin
                  rf_blk_great_hgt_in <= chma_ref_height_y_in;
               end
               rf_blk_hgt_ch <= chma_ref_height_y_in >> (C_SUB_HEIGHT-1);
               d_block_y_offset_chma <= 0;
               d_block_y_end_chma <= chma_ref_height_y_in >> (C_SUB_HEIGHT-1);
            end

            ref_idx_in <= ref_idx_in_in;
         end
      end
	end
end

endmodule