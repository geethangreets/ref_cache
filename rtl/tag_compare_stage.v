`timescale 1ns / 1ps
module tag_compare_stage
(

   clk                           ,
   reset                         ,
   dest_enable_wire_valid        ,
   last_block_valid_1d           ,
   is_hit                        ,
   set_idx                       ,
   set_addr_d                    ,   
   tag_addr                      ,
   ref_idx_in_d                  ,
   luma_dest_enable_wire         ,
   chma_dest_enable_wire         ,
   
   curr_x_d                      ,
   curr_y_d                      ,
   delta_x_d                     ,
   delta_y_d                     , 
   curr_x_2d                     ,
   curr_y_2d                     ,
   delta_x_2d                    ,
   delta_y_2d                    ,
   
   
   cl_strt_x_luma_d              ,
   cl_strt_x_chma_d              ,
   cl_strt_y_luma_d              ,
   cl_strt_y_chma_d              ,
   
   dst_strt_x_luma               ,
   dest_end_x_luma               ,
   dst_strt_y_luma               ,
   dest_end_y_luma               ,
   
   dst_strt_x_chma               ,
   dest_end_x_chma               ,
   dst_strt_y_chma               ,
   dest_end_y_chma               ,   
   
   miss_elem_fifo_full           ,
   ref_pix_axi_ar_fifo_full      ,  
   hit_elem_fifo_full            ,
   op_conf_fifo_program_full     ,  
   
   curr_x_addr_reg               ,
   curr_y_addr_reg               ,
   
   tag_compare_stage_ready       ,
   tag_compare_stage_ready_d     ,
   ref_pix_axi_ar_valid_fifo_in  ,  
   ref_pix_axi_ar_addr_fifo_in   ,
   set_addr_2d                   ,
   miss_elem_fifo_wr_en          ,
   hit_elem_fifo_wr_en           ,
   last_block_valid_2d           ,
   is_hit_d                      ,
   block_number_3                ,
   set_idx_d                     ,
   tag_addr_d                    ,
   luma_dest_enable_reg          ,
   chma_dest_enable_reg          ,
   
   cl_strt_x_luma_2d             ,
   cl_strt_x_chma_2d             ,
   cl_strt_y_luma_2d             ,
   cl_strt_y_chma_2d             ,
   
   dst_strt_x_luma_d             ,
   dest_end_x_luma_d             ,
   dst_strt_y_luma_d             ,
   dest_end_y_luma_d             ,
   
   dst_strt_x_chma_d             ,
   dest_end_x_chma_d             ,
   dst_strt_y_chma_d             ,
   dest_end_y_chma_d
   
   
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
    
   input                                                                clk;
   input                                                                reset;
   input                                                                dest_enable_wire_valid;
   input                                                                last_block_valid_1d;
   input                                                                is_hit;
   input   [C_N_WAY-1:0]                                                set_idx;
   input   [SET_ADDR_WDTH -1:0]                                         set_addr_d;   
   input   [TAG_ADDR_WDTH-1:0]                                          tag_addr;
   input   [REF_ADDR_WDTH-1:0]                                          ref_idx_in_d;
   input                                                                luma_dest_enable_wire;
   input                                                                chma_dest_enable_wire;
   
   input    [C_L_H_SIZE-1:0]                                            cl_strt_x_luma_d;
   input    [C_L_H_SIZE_C-1:0]                                          cl_strt_x_chma_d;
   input    [C_L_V_SIZE-1:0]                                            cl_strt_y_luma_d;
   input    [C_L_V_SIZE_C-1:0]                                          cl_strt_y_chma_d;
   
   input     [LUMA_DIM_WDTH-1:0]                                        dst_strt_x_luma;
   input     [LUMA_DIM_WDTH-1:0]                                        dest_end_x_luma;
   input     [LUMA_DIM_WDTH-1:0]                                        dst_strt_y_luma;
   input     [LUMA_DIM_WDTH-1:0]                                        dest_end_y_luma;
   
   input     [CHMA_DIM_WDTH-1:0]                                        dst_strt_x_chma;
   input     [CHMA_DIM_WDTH-1:0]                                        dest_end_x_chma;
   input     [CHMA_DIM_HIGT-1:0]                                        dst_strt_y_chma;
   input     [CHMA_DIM_HIGT-1:0]                                        dest_end_y_chma;   

   
   input     [X_ADDR_WDTH - C_L_H_SIZE -1: 0]                           curr_x_addr_reg;
   input     [Y_ADDR_WDTH - C_L_V_SIZE -1: 0]                           curr_y_addr_reg;
   
   input                                                                miss_elem_fifo_full        ;
   input                                                                ref_pix_axi_ar_fifo_full   ;
   input                                                                hit_elem_fifo_full         ;
   input                                                                op_conf_fifo_program_full  ; 


   input [1:0]          curr_x_d                      ;
   input [1:0]          curr_y_d                      ;
   input [1:0]          delta_x_d                     ;
   input [1:0]          delta_y_d                     ;
   output reg [1:0]     curr_x_2d                     ;  
   output reg [1:0]     curr_y_2d                     ;
   output reg [1:0]     delta_x_2d                    ;
   output reg [1:0]     delta_y_2d                    ;
   
	output reg                                                           tag_compare_stage_ready;
	output reg                                                           tag_compare_stage_ready_d;
   output reg							            		                     ref_pix_axi_ar_valid_fifo_in;  
   output reg [AXI_ADDR_WDTH-1:0]		                                 ref_pix_axi_ar_addr_fifo_in;
   output reg    [SET_ADDR_WDTH -1:0]                                   set_addr_2d;
   output reg                                                           miss_elem_fifo_wr_en;
   output reg                                                           hit_elem_fifo_wr_en;
   output reg                                                           last_block_valid_2d;
   output reg                                                           is_hit_d;
   output        [BLOCK_NUMBER_WIDTH-1:0]                               block_number_3;
   output reg    [C_N_WAY-1:0]                                          set_idx_d;
   output reg    [TAG_ADDR_WDTH-1:0]                                    tag_addr_d;
   output reg                                                           luma_dest_enable_reg;
   output reg                                                           chma_dest_enable_reg;

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

   reg [15: 0]  bu_idx_val;
   reg [20: 0]  iu_idx_val;
   reg [25: 0]  iu_idx_row_val;
   reg [31: 0]  ref_idx_val;
   
    
   wire [CTB_SIZE_WIDTH - C_L_V_SIZE-1:0] 		bu_idx 		;
   wire [CTB_SIZE_WIDTH - C_L_H_SIZE-1:0] 		bu_row_idx 	;
   
   wire [X_ADDR_WDTH -CTB_SIZE_WIDTH-1:0]  	   iu_idx 	   ;
   wire [Y_ADDR_WDTH -CTB_SIZE_WIDTH-1:0]  	   iu_row_idx  ;
   
   reg [5:0] block_number_3_a;
   reg [5:0] block_number_3_a2;
   
//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

   assign block_number_3 = {block_number_3_a};

   assign iu_idx	      = {curr_x_addr_reg[X_ADDR_WDTH - C_L_H_SIZE -1:CTB_SIZE_WIDTH - C_L_H_SIZE]};
   assign iu_row_idx 	= {curr_y_addr_reg[Y_ADDR_WDTH - C_L_V_SIZE -1:CTB_SIZE_WIDTH - C_L_V_SIZE]};
   assign bu_idx 		   = {curr_x_addr_reg[2:0]};
   assign bu_row_idx 	= {curr_y_addr_reg[2:0]};
   

always@(posedge clk) begin : TAG_COMPARE_STAGE
	if(reset) begin
		ref_pix_axi_ar_valid_fifo_in <= 0;
		iu_idx_val <= 0;
		iu_idx_row_val <= 0;
		ref_idx_val <= 0;
		bu_idx_val <= 0;
		set_addr_2d <= 0;
		miss_elem_fifo_wr_en <= 0;
		hit_elem_fifo_wr_en <= 0;
		last_block_valid_2d <= 0;
		block_number_3_a  <= 0;
      block_number_3_a2 <= 0;
	end
	else begin
				miss_elem_fifo_wr_en <= 0;	
				hit_elem_fifo_wr_en  <= 0;
				ref_pix_axi_ar_valid_fifo_in <= 0;	
				if(dest_enable_wire_valid & tag_compare_stage_ready_d) begin			
               
				
					last_block_valid_2d  <= last_block_valid_1d;
					is_hit_d       <= is_hit;
					set_idx_d      <= set_idx;
					set_addr_2d    <= set_addr_d;
					tag_addr_d     <= tag_addr;
               
               curr_x_2d            <= curr_x_d    ;
               curr_y_2d            <= curr_y_d    ;               
               delta_x_2d           <= delta_x_d   ;               
               delta_y_2d           <= delta_y_d   ;
               
               if((curr_x_d==delta_x_d) && (curr_y_d==delta_y_d)) begin
                  block_number_3_a2 <= block_number_3_a2 + 1;
               end
               block_number_3_a <= block_number_3_a2;
               // block_number_3_b2 <= block_number_3_b1;
               // block_number_3_b1 <= last_block_valid_1d ? 0 : block_number_3_b1+1;
               
					if(!is_hit) begin
                  
						ref_pix_axi_ar_valid_fifo_in <= 1;
						miss_elem_fifo_wr_en <= 1;
                  
						iu_idx_val <= iu_idx * `REF_PIX_IU_OFFSET;
						iu_idx_row_val <= iu_row_idx * `REF_PIX_IU_ROW_OFFSET;
						ref_idx_val <= ref_idx_in_d * `REF_PIX_FRAME_OFFSET;
						if(C_SIZE == 13) begin
							bu_idx_val <= bu_idx * `REF_PIX_BU_OFFSET + bu_row_idx * `REF_PIX_BU_ROW_OFFSET;
						end
						else begin
							// bu_idx_val <= bu_idx * `REF_PIX_BU_OFFSET_OLD + bu_row_idx * `REF_PIX_BU_ROW_OFFSET;
                     $stop;
                     $display("depricated");
						end	
						
					end
					else begin
						hit_elem_fifo_wr_en <= 1;
						ref_pix_axi_ar_valid_fifo_in <= 0;	
					end
					luma_dest_enable_reg <= luma_dest_enable_wire;
					chma_dest_enable_reg <= chma_dest_enable_wire;			

               cl_strt_x_luma_2d <= cl_strt_x_luma_d;
               cl_strt_x_chma_2d <= cl_strt_x_chma_d;
               cl_strt_y_luma_2d <= cl_strt_y_luma_d;
               cl_strt_y_chma_2d <= cl_strt_y_chma_d;
               dst_strt_x_luma_d <= dst_strt_x_luma;
               dest_end_x_luma_d <= dest_end_x_luma;
               dst_strt_y_luma_d <= dst_strt_y_luma;
               dest_end_y_luma_d <= dest_end_y_luma;
               
               dst_strt_x_chma_d <= dst_strt_x_chma;
               dest_end_x_chma_d <= dest_end_x_chma;
               dst_strt_y_chma_d <= dst_strt_y_chma;
               dest_end_y_chma_d <= dest_end_y_chma;
						
				end
			
	end
end

always@(posedge clk) begin
   tag_compare_stage_ready_d <= tag_compare_stage_ready;
end

always@(*) begin
	ref_pix_axi_ar_addr_fifo_in = bu_idx_val  + iu_idx_val + iu_idx_row_val + ref_idx_val;
end


always@(*) begin
			tag_compare_stage_ready = 1;
         // if(!is_hit) begin
            if(miss_elem_fifo_full || ref_pix_axi_ar_fifo_full || hit_elem_fifo_full || op_conf_fifo_program_full) begin
               tag_compare_stage_ready = 0;
            end
         // end
         // else begin
            // if(hit_elem_fifo_full ) begin
               // tag_compare_stage_ready = 0;	
            // end
         // end
end

endmodule