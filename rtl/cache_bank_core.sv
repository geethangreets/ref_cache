`timescale 1ns / 1ps
module cache_bank_core
(
   clk,
   reset,
   curr_x_luma,   
   curr_y_luma,   

   curr_x_chma,   
   curr_y_chma, 

   curr_x,
   curr_y,   
      
   delta_x,
   delta_y,   
      
   cur_xy_changed_luma,
   cur_xy_changed_chma, 

   start_x_in,
   start_y_in,
   start_x_ch,    
   start_y_ch,
   
   curr_x_addr,
   curr_y_addr,
   ref_idx_in,
   
   d_block_x_offset_luma,     
   d_block_y_offset_luma,
   d_block_x_offset_chma,
   d_block_y_offset_chma, 
   
   miss_elem_fifo_full      ,
   ref_pix_axi_ar_fifo_full ,   
   ref_pix_axi_aw_fifo_full ,   
   hit_elem_fifo_full       ,   
   op_conf_fifo_program_full,   
   
                                                    
   rf_blk_hgt_in,
   rf_blk_wdt_in,
   rf_blk_hgt_ch,
   rf_blk_wdt_ch,  
   
   delta_x_luma,     
   delta_y_luma,     
   delta_x_chma,  
   delta_y_chma,  
   
   set_input_stage_valid,
   is_req_read_in,
   last_block_valid_0d,
   
   dest_enable_wire_valid,
   tag_compare_stage_ready,  
   tag_compare_stage_ready_d,  
   ref_pix_axi_ar_valid_fifo_in,  
   ref_pix_axi_aw_valid_fifo_in,  
   ref_pix_axi_ar_addr_fifo_in,
   set_addr_2d,
   is_req_read_misq,
   miss_elem_fifo_wr_en,
   hit_elem_fifo_wr_en,
   last_block_valid_2d,
   
   block_number_3,
   set_idx_d     ,
   luma_dest_enable_reg,
   chma_dest_enable_reg,
   
   set_idx_miss   ,

   curr_x_2d      ,
   curr_y_2d      ,
   delta_x_2d     ,
   delta_y_2d     ,

   cl_strt_x_luma_2d,
   cl_strt_x_chma_2d,
   cl_strt_y_luma_2d,
   cl_strt_y_chma_2d,
   
   dst_strt_x_luma_d,
   dest_end_x_luma_d,
   dst_strt_y_luma_d,
   dest_end_y_luma_d,
   
   dst_strt_x_chma_d,
   dest_end_x_chma_d,
   dst_strt_y_chma_d,
   dest_end_y_chma_d


);

    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"
    `include "../sim/cache_configs_def.v"
    
	parameter YY_WIDTH = PIXEL_WIDTH*DBF_OUT_Y_BLOCK_SIZE*DBF_OUT_Y_BLOCK_SIZE;
	parameter CH_WIDTH = PIXEL_WIDTH*DBF_OUT_CH_BLOCK_HIGHT*DBF_OUT_CH_BLOCK_WIDTH;

    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------

    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
   input                                            clk;
   input                                            reset;
   input    [1:0]                                   curr_x_luma; // possible 0,1,2
   input    [1:0]                                   curr_y_luma; // possible 0,1,2,3
   
   input    [1:0]                                   curr_x;
   input    [1:0]                                   curr_y;
   
   input    [1:0]                                   delta_x;
   input    [1:0]                                   delta_y;

   input    [1:0]                                   curr_x_chma; // possible 0,1,2
   input    [1:0]                                   curr_y_chma; // possible 0,1,2,3
   
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
   
   input                                            miss_elem_fifo_full       ;
   input                                            ref_pix_axi_ar_fifo_full  ;
   input                                            ref_pix_axi_aw_fifo_full  ;
   input                                            hit_elem_fifo_full        ;
   input                                            op_conf_fifo_program_full ;
   
   input       set_input_stage_valid;
   input       is_req_read_in;
   input       last_block_valid_0d;
   output                                                               dest_enable_wire_valid;   
	output                                                              tag_compare_stage_ready;
	output                                                              tag_compare_stage_ready_d;   
   output reg							            		            ref_pix_axi_ar_valid_fifo_in;  
   output reg							            		            ref_pix_axi_aw_valid_fifo_in;  
   output reg [AXI_ADDR_WDTH-1:0]		                                ref_pix_axi_ar_addr_fifo_in;
   output reg    [SET_ADDR_WDTH -1:0]                                   set_addr_2d;
   output reg                                                           is_req_read_misq;
   output reg                                                           miss_elem_fifo_wr_en;
   output reg                                                           hit_elem_fifo_wr_en;
   output reg                                                           last_block_valid_2d;

   output [1:0]                                                         curr_x_2d    ;
   output [1:0]                                                         curr_y_2d    ;
   output [1:0]                                                         delta_x_2d   ;
   output [1:0]                                                         delta_y_2d   ;
   
   output reg    [BLOCK_NUMBER_WIDTH-1:0]                               block_number_3;
   output reg    [C_N_WAY-1:0]                                          set_idx_d;
   output reg                                                           luma_dest_enable_reg;
   output reg                                                           chma_dest_enable_reg;
   
   output        [C_N_WAY-1:0]                                          set_idx_miss;

   output reg     [C_L_H_SIZE-1:0]                                      cl_strt_x_luma_2d;
   output reg     [C_L_H_SIZE_C-1:0]                                    cl_strt_x_chma_2d;
   output reg     [C_L_V_SIZE-1:0]                                      cl_strt_y_luma_2d;
   output reg     [C_L_V_SIZE_C-1:0]                                    cl_strt_y_chma_2d;
   
   output reg     [LUMA_DIM_WDTH-1:0]                                   dst_strt_x_luma_d;
   output reg     [LUMA_DIM_WDTH-1:0]                                   dest_end_x_luma_d;
   output reg     [LUMA_DIM_WDTH-1:0]                                   dst_strt_y_luma_d;
   output reg     [LUMA_DIM_WDTH-1:0]                                   dest_end_y_luma_d;
   
   output reg     [CHMA_DIM_WDTH-1:0]                                   dst_strt_x_chma_d;
   output reg     [CHMA_DIM_WDTH-1:0]                                   dest_end_x_chma_d;
   output reg     [CHMA_DIM_HIGT-1:0]                                   dst_strt_y_chma_d;
   output reg     [CHMA_DIM_HIGT-1:0]                                   dest_end_y_chma_d;


   
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------   
wire    [SET_ADDR_WDTH -1:0]                     set_addr;
wire    [SET_ADDR_WDTH -1:0]                     set_addr_d;
                                                 
reg     [SET_ADDR_WDTH+C_N_WAY-1:0]              tag_write_addr;
wire    [(1<<C_N_WAY)*TAG_ADDR_WDTH-1:0]         tag_rdata_set;
                                                 
reg                                              tag_mem_wr_en;
wire    [(1<<C_N_WAY)-1:0]                       set_vld_bits;
                                                 
wire    [(1<<C_N_WAY)*C_N_WAY-1:0]               age_val_set;
wire    [(1<<C_N_WAY)*C_N_WAY-1:0]               new_age_set;
reg                                              age_wr_en;
                                                 
wire    [TAG_ADDR_WDTH-1:0]                      tag_addr;
wire    [TAG_ADDR_WDTH-1:0]                      tag_addr_d;
                                                 
wire                                             is_hit;
wire                                             is_hit_d;
wire    [C_N_WAY-1:0]                            set_idx;

wire    [X_ADDR_WDTH - C_L_H_SIZE -1: 0]         curr_x_addr_reg;
wire    [Y_ADDR_WDTH - C_L_V_SIZE -1: 0]         curr_y_addr_reg;

wire       [X_ADDR_WDTH-1:0]                     start_x_in_d;
wire       [Y_ADDR_WDTH-1:0]                     start_y_in_d;
wire       [X_ADDR_WDTH-(C_SUB_WIDTH -1)-1:0]    start_x_ch_d; //% value after division by two
wire       [Y_ADDR_WDTH-(C_SUB_HEIGHT-1)-1:0]    start_y_ch_d;

wire        [LUMA_DIM_WDTH-1:0]                  rf_blk_hgt_in_d;
wire        [LUMA_DIM_WDTH-1:0]                  rf_blk_wdt_in_d;
wire        [CHMA_DIM_HIGT-1:0]                  rf_blk_hgt_ch_d;
wire        [CHMA_DIM_WDTH-1:0]                  rf_blk_wdt_ch_d;  

wire                                             luma_dest_enable_wire;
wire                                             chma_dest_enable_wire;

wire                                             last_block_valid_1d;
wire                                             last_block_valid_0d;
wire         [REF_ADDR_WDTH-1:0]                 ref_idx_in_d;
wire    [C_L_H_SIZE-1:0]                         cl_strt_x_luma_d;
wire    [C_L_V_SIZE-1:0]                         cl_strt_y_luma_d;
wire    [C_L_H_SIZE_C-1:0]                       cl_strt_x_chma_d;
wire    [C_L_V_SIZE_C-1:0]                       cl_strt_y_chma_d;

wire     [LUMA_DIM_WDTH-1:0] dst_strt_x_luma;
wire     [LUMA_DIM_WDTH-1:0] dest_end_x_luma;
wire     [LUMA_DIM_WDTH-1:0] dst_strt_y_luma;
wire     [LUMA_DIM_WDTH-1:0] dest_end_y_luma;

wire     [CHMA_DIM_WDTH-1:0] dst_strt_x_chma;
wire     [CHMA_DIM_WDTH-1:0] dest_end_x_chma;
wire     [CHMA_DIM_HIGT-1:0] dst_strt_y_chma;
wire     [CHMA_DIM_HIGT-1:0] dest_end_y_chma;

wire [1:0] curr_x_d  ;
wire [1:0] curr_y_d  ;
wire [1:0] delta_x_d ;
wire [1:0] delta_y_d ;


wire is_req_read_tag_read;


//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

always@(*) begin
	tag_mem_wr_en = 0;
   tag_write_addr = {set_addr_2d,set_idx_miss};		
	if(miss_elem_fifo_wr_en) begin 
		tag_mem_wr_en = 1;						
	end
end

always@(posedge clk) begin
	if(reset) begin
		age_wr_en <= 0;
	end
	else begin
      if(dest_enable_wire_valid & tag_compare_stage_ready_d) begin
         age_wr_en <= 1;
      end
      else begin
         age_wr_en <= 0;
      end
	end
end


	tag_memory_write_first tag_block (
    .clk(clk), 
    .reset(reset), 
    .r_addr_in(set_addr), 
    .w_addr_in(tag_write_addr), 
    .r_data_out(tag_rdata_set), 
    .w_data_in(tag_addr_d), 
    .w_en_in(tag_mem_wr_en), 
    .valid_bits_out(set_vld_bits)
    );
	

	age_memory age_block (
    .clk(clk), 
    .reset(reset), 
    .r_addr_in(set_addr_d), 
    .w_addr_in(set_addr_2d), 
    .r_data_out(age_val_set), 
    .w_data_in(new_age_set),
    .w_en_in(age_wr_en)
    );


    compare_tags_new tag_compare_block (
    .tags_set_in(tag_rdata_set), 
    .the_tag_in(tag_addr), 
    .ishit(is_hit), 
    .set_idx(set_idx),
    .valid_bits_in(set_vld_bits)
    );
    
    new_age_converter age_conv_block (
    .ishit_in(is_hit_d), 
    .set_idx_in(set_idx_d), 
    .age_vals_in(age_val_set), 
    .new_age_vals_out(new_age_set), 
    .set_idx_miss_bnk_out(set_idx_miss)
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
 luma_dest_en_old
(
   .x_addr      (curr_x_addr_reg       ),
   .y_addr      (curr_y_addr_reg       ),
   .start_x     (start_x_in_d          ),
   .start_y     (start_y_in_d          ),
   .blk_width   (rf_blk_wdt_in_d       ),
   .blk_height  (rf_blk_hgt_in_d       ),
   .dest_enable (luma_dest_enable_wire )
);


 cache_dest_enable
 #(
   .START_X_WDTH  (X_ADDR_WDTH-(C_SUB_WIDTH -1)),
   .START_Y_WDTH  (Y_ADDR_WDTH-(C_SUB_HEIGHT-1)),
   .XXMA_DIM_WDTH (CHMA_DIM_WDTH),
   .XXMA_DIM_HIGT (CHMA_DIM_HIGT),
   .SHIFT_H       (C_L_H_SIZE_C),
   .SHIFT_V       (C_L_V_SIZE_C)
 )
 chma_dest_en_old
(
   .x_addr      (curr_x_addr_reg       ),
   .y_addr      (curr_y_addr_reg       ),
   .start_x     (start_x_ch_d          ),
   .start_y     (start_y_ch_d          ),
   .blk_width   (rf_blk_wdt_ch_d       ),
   .blk_height  (rf_blk_hgt_ch_d       ),
   .dest_enable (chma_dest_enable_wire )
);





tag_read_stage tag_read_stage_block
(
   .clk                       (clk                       ),
   .reset                     (reset                     ),
   
   .dest_enable_wire_valid    (dest_enable_wire_valid    ),
   .is_req_read_out           (is_req_read_tag_read      ),
   .set_input_stage_valid     (set_input_stage_valid     ),
   .is_req_read_in            (is_req_read_in            ),
   .tag_compare_stage_ready_d (tag_compare_stage_ready_d ),
   .last_block_valid_1d       (last_block_valid_1d       ),
   .last_block_valid_0d       (last_block_valid_0d       ),
   
   .ref_idx_in                (ref_idx_in                ),
   .curr_x_addr               (curr_x_addr               ),
   .curr_y_addr               (curr_y_addr               ),
   .curr_x_luma               (curr_x_luma               ),
   .curr_y_luma               (curr_y_luma               ),
   .curr_x_chma               (curr_x_chma               ),
   .curr_y_chma               (curr_y_chma               ),
   .cur_xy_changed_luma       (cur_xy_changed_luma       ),
   .cur_xy_changed_chma       (cur_xy_changed_chma       ),
   
   .d_block_x_offset_luma     (d_block_x_offset_luma     ),
   .d_block_y_offset_luma     (d_block_y_offset_luma     ),   
   .d_block_x_offset_chma     (d_block_x_offset_chma     ),   
   .d_block_y_offset_chma     (d_block_y_offset_chma     ), 
   
   .rf_blk_hgt_in             (rf_blk_hgt_in             ),
   .rf_blk_wdt_in             (rf_blk_wdt_in             ),   
   .rf_blk_hgt_ch             (rf_blk_hgt_ch             ),   
   .rf_blk_wdt_ch             (rf_blk_wdt_ch             ),
   
   .delta_x_luma              (delta_x_luma              ),
   .delta_y_luma              (delta_y_luma              ),   
   .delta_x_chma              (delta_x_chma              ),   
   .delta_y_chma              (delta_y_chma              ),
   
   .start_x_in                (start_x_in                ),
   .start_y_in                (start_y_in                ),
   .start_x_ch                (start_x_ch                ),
   .start_y_ch                (start_y_ch                ),
   

   .curr_x                    (curr_x                    ),
   .curr_y                    (curr_y                    ),
   .delta_x                   (delta_x                   ),
   .delta_y                   (delta_y                   ),
   .curr_x_d                  (curr_x_d                  ),
   .curr_y_d                  (curr_y_d                  ),
   .delta_x_d                 (delta_x_d                 ),
   .delta_y_d                 (delta_y_d                 ),
   
   .curr_x_addr_reg           (curr_x_addr_reg           ),
   .curr_y_addr_reg           (curr_y_addr_reg           ),
   .set_addr                  (set_addr                  ),
   .set_addr_d                (set_addr_d                ),
   .tag_addr                  (tag_addr                  ),
   
   .rf_blk_hgt_in_d           (rf_blk_hgt_in_d           ),
   .rf_blk_wdt_in_d           (rf_blk_wdt_in_d           ),
   .rf_blk_hgt_ch_d           (rf_blk_hgt_ch_d           ),
   .rf_blk_wdt_ch_d           (rf_blk_wdt_ch_d           ),
   
   .start_x_in_d              (start_x_in_d              ),
   .start_y_in_d              (start_y_in_d              ),
   .start_x_ch_d              (start_x_ch_d              ),
   .start_y_ch_d              (start_y_ch_d              ),
   
   .ref_idx_in_d              (ref_idx_in_d              ),
   .cl_strt_x_luma_d          (cl_strt_x_luma_d          ),
   .cl_strt_y_luma_d          (cl_strt_y_luma_d          ),
   .cl_strt_x_chma_d          (cl_strt_x_chma_d          ),
   .cl_strt_y_chma_d          (cl_strt_y_chma_d          ),
   
   .dest_end_x_luma           (dest_end_x_luma           ),
   .dst_strt_x_luma           (dst_strt_x_luma           ),
   .dest_end_y_luma           (dest_end_y_luma           ),
   .dst_strt_y_luma           (dst_strt_y_luma           ),
   
   .dest_end_x_chma           (dest_end_x_chma           ),
   .dst_strt_x_chma           (dst_strt_x_chma           ),
   .dest_end_y_chma           (dest_end_y_chma           ),
   .dst_strt_y_chma           (dst_strt_y_chma           )
   
);


tag_compare_stage 
#(
.BLOCK_NUMBER_WIDTH(BLOCK_NUMBER_WIDTH)
)
tag_compare_pipe_stage
(
   .clk                          (clk                          ) ,
   .reset                        (reset                        ) ,
   .dest_enable_wire_valid       (dest_enable_wire_valid       ) ,
   .is_req_read_in               (is_req_read_tag_read         ) ,
   .last_block_valid_1d          (last_block_valid_1d          ) ,
   .is_hit                       (is_hit                       ) ,
   .set_idx                      (set_idx                      ) ,
   .set_addr_d                   (set_addr_d                   ) ,   
   .tag_addr                     (tag_addr                     ) ,
   .ref_idx_in_d                 (ref_idx_in_d                 ) ,
   .luma_dest_enable_wire        (luma_dest_enable_wire        ) ,
   .chma_dest_enable_wire        (chma_dest_enable_wire        ) ,
   
   .cl_strt_x_luma_d             (cl_strt_x_luma_d             ) ,
   .cl_strt_x_chma_d             (cl_strt_x_chma_d             ) ,
   .cl_strt_y_luma_d             (cl_strt_y_luma_d             ) ,
   .cl_strt_y_chma_d             (cl_strt_y_chma_d             ) ,
   
   .dst_strt_x_luma              (dst_strt_x_luma              ) ,
   .dest_end_x_luma              (dest_end_x_luma              ) ,
   .dst_strt_y_luma              (dst_strt_y_luma              ) ,
   .dest_end_y_luma              (dest_end_y_luma              ) ,
   
   .dst_strt_x_chma              (dst_strt_x_chma              ) ,
   .dest_end_x_chma              (dest_end_x_chma              ) ,
   .dst_strt_y_chma              (dst_strt_y_chma              ) ,
   .dest_end_y_chma              (dest_end_y_chma              ) ,
   
   .miss_elem_fifo_full          (miss_elem_fifo_full          ) ,
   .ref_pix_axi_ar_fifo_full     (ref_pix_axi_ar_fifo_full     ) ,  
   .ref_pix_axi_aw_fifo_full     (ref_pix_axi_aw_fifo_full     ) ,  
   .hit_elem_fifo_full           (hit_elem_fifo_full           ) ,
   .op_conf_fifo_program_full    (op_conf_fifo_program_full    ) , 
   
   .curr_x_addr_reg              (curr_x_addr_reg              ) ,
   .curr_y_addr_reg              (curr_y_addr_reg              ) ,
   
   .curr_x_d                     (curr_x_d                     ),
   .curr_y_d                     (curr_y_d                     ),   
   .delta_x_d                    (delta_x_d                    ),   
   .delta_y_d                    (delta_y_d                    ),   
   
   .curr_x_2d                     (curr_x_2d                   ),
   .curr_y_2d                     (curr_y_2d                   ),   
   .delta_x_2d                    (delta_x_2d                  ),   
   .delta_y_2d                    (delta_y_2d                  ),  
   
   .tag_compare_stage_ready      (tag_compare_stage_ready      ) ,
   .tag_compare_stage_ready_d    (tag_compare_stage_ready_d    ) ,
   .ref_pix_axi_ar_valid_fifo_in (ref_pix_axi_ar_valid_fifo_in ) ,  
   .ref_pix_axi_aw_valid_fifo_in (ref_pix_axi_aw_valid_fifo_in ) ,  
   .ref_pix_axi_ar_addr_fifo_in  (ref_pix_axi_ar_addr_fifo_in  ) ,
   .set_addr_2d                  (set_addr_2d                  ) ,
   .miss_elem_fifo_wr_en         (miss_elem_fifo_wr_en         ) ,
   .hit_elem_fifo_wr_en          (hit_elem_fifo_wr_en          ) ,
   .last_block_valid_2d          (last_block_valid_2d          ) ,
   .is_hit_d                     (is_hit_d                     ) ,
   .is_req_read_out              (is_req_read_misq             ) ,
   .block_number_3               (block_number_3               ) ,
   .set_idx_d                    (set_idx_d                    ) ,
   .tag_addr_d                   (tag_addr_d                   ) ,
   .luma_dest_enable_reg         (luma_dest_enable_reg         ) ,
   .chma_dest_enable_reg         (chma_dest_enable_reg         ) ,
   
   .cl_strt_x_luma_2d            (cl_strt_x_luma_2d            ) ,
   .cl_strt_x_chma_2d            (cl_strt_x_chma_2d            ) ,
   .cl_strt_y_luma_2d            (cl_strt_y_luma_2d            ) ,
   .cl_strt_y_chma_2d            (cl_strt_y_chma_2d            ) ,
   
   .dst_strt_x_luma_d            (dst_strt_x_luma_d            ) ,
   .dest_end_x_luma_d            (dest_end_x_luma_d            ) ,
   .dst_strt_y_luma_d            (dst_strt_y_luma_d            ) ,
   .dest_end_y_luma_d            (dest_end_y_luma_d            ) ,
   
   .dst_strt_x_chma_d            (dst_strt_x_chma_d            ) ,
   .dest_end_x_chma_d            (dest_end_x_chma_d            ) ,
   .dst_strt_y_chma_d            (dst_strt_y_chma_d            ) ,
   .dest_end_y_chma_d            (dest_end_y_chma_d            )
   
);





endmodule
