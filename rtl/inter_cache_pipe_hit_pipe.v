`timescale 1ns / 1ps
module inter_cache_pipe_hit_pipe
(
    clk,
    reset,
    
    luma_ref_start_x_in 	,   // start x location of luma 
    luma_ref_start_y_in     ,    // start y location of luma 
    chma_ref_start_x_in 	,   // start x location of chroma 
    chma_ref_start_y_in 	,   // start y location of chroma 
    ref_idx_in_in,              // default to zero (for current frame)
    valid_in     ,             // input valid
    is_req_read  ,              // input valid
    wb_data_in   ,
    cache_idle_out,         // 1 - cache is ready to accept new input
    
    luma_ref_width_x_in   ,     //width of reference block in luma
    chma_ref_width_x_in   ,     //width of reference block in chroma
    luma_ref_height_y_in  ,     //height of reference block in luma
    chma_ref_height_y_in  ,     //height of reference block in chroma

    luma_ref_start_x_out     ,  //block dimension output for reference
    luma_ref_start_y_out    ,   //block dimension output for reference
    chma_ref_start_x_out     ,  //block dimension output for reference
    chma_ref_start_y_out     ,  //block dimension output for reference
    
    luma_ref_width_x_out   ,    //block dimension output for reference
    chma_ref_width_x_out   ,    //block dimension output for reference
    luma_ref_height_y_out  ,    //block dimension output for reference
    chma_ref_height_y_out  ,    //block dimension output for reference
    
	block_x_offset_luma ,   // valid pixel starting location x direction in luma output
    block_y_offset_luma ,   // valid pixel starting location y direction in luma output
    block_x_offset_chma ,   // valid pixel starting location x direction in chroma output
    block_y_offset_chma ,   // valid pixel starting location y direction in chroma output
    block_x_end_luma    ,   // valid pixel ending location x direction in luma output
    block_y_end_luma    ,   // valid pixel ending location y direction in luma output
    block_x_end_chma    ,   // valid pixel ending location x direction in chroma output
    block_y_end_chma    ,   // valid pixel ending location y direction in chroma output

    


    pic_width           ,
    pic_height          ,

    ch_frac_x           ,       //optional default to zero
    ch_frac_y           ,       //optional default to zero
    ch_frac_x_out       ,      //optional 
    ch_frac_y_out       ,      //optional


    filer_idle_in       ,      // 1 means down stream module is ready to accept new data
    luma_ref_block_out  , // y reference block
    cb_ref_block_out    ,   // cb reference block
    cr_ref_block_out    ,   // cr reference block
    cache_valid_out     ,    //1 - valid output
    
    ref_pix_axi_ar_addr ,
    ref_pix_axi_ar_len  ,
    ref_pix_axi_ar_size ,
    ref_pix_axi_ar_burst,
    ref_pix_axi_ar_prot ,
    ref_pix_axi_ar_valid,
    ref_pix_axi_ar_ready,
    ref_pix_axi_r_data  ,
    ref_pix_axi_r_resp  ,
    ref_pix_axi_r_last  ,
    ref_pix_axi_r_valid ,
    ref_pix_axi_r_ready
    
    ,ref_pix_axi_awid    
    ,ref_pix_axi_awlen       
    ,ref_pix_axi_awsize      
    ,ref_pix_axi_awburst     
    ,ref_pix_axi_awlock  
    ,ref_pix_axi_awcache     
    ,ref_pix_axi_awprot      
    ,ref_pix_axi_awvalid	    
    ,ref_pix_axi_awaddr	    
    ,ref_pix_axi_awready	    
        
    ,ref_pix_axi_wstrb	    
    ,ref_pix_axi_wlast	    
    ,ref_pix_axi_wvalid	    
    ,ref_pix_axi_wdata	    
    ,ref_pix_axi_wready	    
        
    ,ref_pix_axi_bid		    
    ,ref_pix_axi_bresp	    
    ,ref_pix_axi_bvalid	    
    ,ref_pix_axi_bready	    
    
	,cache_full_idle    // asserts when all blocks in cache is fully idle


);

    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"
    `include "../sim/cache_configs_def.v"
    
	parameter YY_WIDTH = PIXEL_WIDTH*DBF_OUT_Y_BLOCK_SIZE*DBF_OUT_Y_BLOCK_SIZE;
	parameter CH_WIDTH = PIXEL_WIDTH*DBF_OUT_CH_BLOCK_HIGHT*DBF_OUT_CH_BLOCK_WIDTH;

    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------

    parameter                           CACHE_LINE_LUMA_OFFSET    = 0;
    parameter                           CACHE_LINE_CB_OFFSET      = CACHE_LINE_WDTH * BIT_DEPTH;
    parameter                           CACHE_LINE_CR_OFFSET      = CACHE_LINE_CB_OFFSET + ((CACHE_LINE_WDTH * BIT_DEPTH)>> ((C_SUB_HEIGHT-1)+(C_SUB_WIDTH-1)));

    parameter                           REF_PIX_AXI_AX_SIZE  = `AX_SIZE_64;
    parameter                           REF_PIX_AXI_AX_LEN   = `AX_LEN_1;

    parameter                           MIS_FIFO_DEPTH = 4;
    parameter                           HIT_FIFO_DEPTH = 6;
    parameter                           OUT_FIFO_DEPTH = 6;
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------

		localparam							STATE_IDLE	 			= 0;
		localparam 							STATE_ACTIVE 			= 1;
		localparam							STATE_PASS_ONLY	 		= 2;
		localparam							STATE_READY_WAIT	 	= 3;
		localparam							STATE_READY_WAIT_ONLY	= 4;
		localparam							STATE_MISS_FULL_WAIT  = 5;
		localparam							STATE_READY_AND_FUL_WAIT  = 6;

    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    

    
    input                                           clk;
    input                                           reset;
                
    // inter prediction filter interface            
   input                                           valid_in; 
   input                                           is_req_read; 
   input [YY_WIDTH+CH_WIDTH*2-1:0]                 wb_data_in;
   wire  [YY_WIDTH+CH_WIDTH*2-1:0]                 wb_data_read;
   output								           cache_valid_out;   // assuming cache_block_ready is single cylce 
   output										   cache_idle_out;
   input                                           filer_idle_in;
   output                                          cache_full_idle;
    
// config IOs

	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_x_in;	
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_y_in;
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_x_in;	
	input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_y_in;	
	
	input  [LUMA_DIM_WDTH - 1:0]   			                chma_ref_width_x_in            ;	
    input  [LUMA_DIM_WDTH - 1:0]                            chma_ref_height_y_in           ;   
	input  [LUMA_DIM_WDTH - 1:0]   			                luma_ref_width_x_in            ;	
    input  [LUMA_DIM_WDTH - 1:0]                            luma_ref_height_y_in           ;  

    output  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]         luma_ref_start_x_out   ;
    output  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]         luma_ref_start_y_out   ;
    output  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]         chma_ref_start_x_out   ;
    output  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]         chma_ref_start_y_out   ;
   
   output   [LUMA_DIM_WDTH - 1:0]                           chma_ref_width_x_out   ;
   output   [LUMA_DIM_WDTH - 1:0]                           chma_ref_height_y_out  ;
   output   [LUMA_DIM_WDTH - 1:0]                           luma_ref_width_x_out   ;
   output   [LUMA_DIM_WDTH - 1:0]                           luma_ref_height_y_out  ;


   input    [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_x;
   input    [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_y;
   output   [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_x_out;
   output   [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_y_out; 
   
   input			[REF_ADDR_WDTH-1:0]		             ref_idx_in_in;
	
   input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   pic_width;   
   input  signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]   pic_height;   
	
		
   output          [LUMA_DIM_WDTH-1:0]                 block_x_offset_luma;
   output          [LUMA_DIM_WDTH-1:0]                 block_y_offset_luma;
   output          [CHMA_DIM_WDTH-1:0]                 block_x_offset_chma;
   output          [CHMA_DIM_HIGT-1:0]                 block_y_offset_chma; 

   output          [LUMA_DIM_WDTH-1:0]                 block_x_end_luma;
   output          [LUMA_DIM_WDTH-1:0]                 block_y_end_luma;
   output          [CHMA_DIM_WDTH-1:0]                 block_x_end_chma;
   output          [CHMA_DIM_HIGT-1:0]                 block_y_end_chma; 
   
   
// datapath outputs	  ------------------------------------------       
   output [BIT_DEPTH* LUMA_REF_BLOCK_WIDTH* LUMA_REF_BLOCK_WIDTH -1:0]     luma_ref_block_out;
   output [BIT_DEPTH* CHMA_REF_BLOCK_WIDTH* CHMA_REF_BLOCK_HIGHT -1:0]     cb_ref_block_out;
   output [BIT_DEPTH* CHMA_REF_BLOCK_WIDTH* CHMA_REF_BLOCK_HIGHT -1:0]     cr_ref_block_out;



               
// axi master interface  ------------------------------------------       
    output      [AXI_ADDR_WDTH-1:0]                                 ref_pix_axi_ar_addr;
    wire        [AXI_ADDR_WDTH-1:0]                                 ref_pix_axi_ar_addr_fifo_in;
    output wire [7:0]                                               ref_pix_axi_ar_len;
    output wire [2:0]                                               ref_pix_axi_ar_size;
    output wire [1:0]                                               ref_pix_axi_ar_burst;
    output wire [2:0]                                               ref_pix_axi_ar_prot;
    output                                                          ref_pix_axi_ar_valid;
    input 								                            ref_pix_axi_ar_ready;
    input       [AXI_CACHE_DATA_WDTH-1:0]                           ref_pix_axi_r_data;
    input       [1:0]                                               ref_pix_axi_r_resp;
    input                                                           ref_pix_axi_r_last;
    input                                                           ref_pix_axi_r_valid;
    output reg                                                      ref_pix_axi_r_ready;
    wire							            	                ref_pix_axi_ar_fifo_empty;
    wire							            	                ref_pix_axi_ar_fifo_full;
    wire							            	                ref_pix_axi_ar_fifo_rd_en;
    
    output                                                          ref_pix_axi_awid    ;
    output      [7:0]                                               ref_pix_axi_awlen   ;
    output      [2:0]                                               ref_pix_axi_awsize  ;
    output      [1:0]                                               ref_pix_axi_awburst ;
    output                        	                                ref_pix_axi_awlock  ;
    output      [3:0]                                               ref_pix_axi_awcache ;
    output      [2:0]                                               ref_pix_axi_awprot  ;
    output                                                          ref_pix_axi_awvalid	;
    output      [AXI_ADDR_WDTH-1:0]                                 ref_pix_axi_awaddr	;
    input                         	                                ref_pix_axi_awready	;
    // write data channel
    output      [AXI_CACHE_DATA_WDTH/8-1:0]	                        ref_pix_axi_wstrb	;
    output                                     	                    ref_pix_axi_wlast	;
    output                                     	                    ref_pix_axi_wvalid	;
    output      [AXI_CACHE_DATA_WDTH -1:0]	                        ref_pix_axi_wdata	;
    input	                                                        ref_pix_axi_wready	;
    //write response channel
    input                       	                                ref_pix_axi_bid		;
    input       [1:0]                                               ref_pix_axi_bresp	;
    input                       	                                ref_pix_axi_bvalid	;
    output                                                          ref_pix_axi_bready	;  
    
    wire							            	                ref_pix_axi_aw_fifo_empty;
    wire							            	                ref_pix_axi_aw_fifo_full ;
    wire							            	                ref_pix_axi_aw_fifo_rd_en;
    wire							            	                wb_data_fifo_empty;
    wire							            	                wb_data_fifo_full ;
    wire							            	                wb_data_fifo_rd_en;
    wire							            	                wb_data_dwnstr_fifo_empty;
    wire							            	                wb_data_dwnstr_fifo_full ;
    wire							            	                wb_data_dwnstr_rd_en ;
    wire		[YY_WIDTH+CH_WIDTH*2-1:0]					        wb_data_dwn_str_rdat;
    // pipeline controlls
    wire set_input_stage_valid;
    wire set_input_ready;

   
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------   


   wire         [REF_ADDR_WDTH-1:0]                 ref_idx_in;   
   wire         [LUMA_DIM_WDTH-1:0]                 rf_blk_hgt_in;
   wire         [LUMA_DIM_WDTH-1:0]                 rf_blk_wdt_in;
   wire         [CHMA_DIM_HIGT-1:0]                 rf_blk_hgt_ch;
   wire         [CHMA_DIM_WDTH-1:0]                 rf_blk_wdt_ch;       

         
   wire       [X_ADDR_WDTH-1:0]                     start_great_x_in;
   wire       [Y_ADDR_WDTH-1:0]                     start_great_y_in;
   wire       [LUMA_DIM_WDTH-1:0]                   rf_blk_great_hgt_in;
   wire       [LUMA_DIM_WDTH-1:0]                   rf_blk_great_wdt_in;    

   wire       [X_ADDR_WDTH-1:0]                     start_x_in;
   wire       [Y_ADDR_WDTH-1:0]                     start_y_in;
   wire       [X_ADDR_WDTH-(C_SUB_WIDTH -1)-1:0]    start_x_ch; //% value after division by two
   wire       [Y_ADDR_WDTH-(C_SUB_HEIGHT-1)-1:0]    start_y_ch;

   wire    [1:0]                                    delta_x;    // possible 0,1,2
   wire    [1:0]                                    delta_y;    //possible 0,1,2,3

   wire    [1:0]                                    delta_x_2d;    // possible 0,1,2
   wire    [1:0]                                    delta_y_2d;    //possible 0,1,2,3
   
   wire     [1:0]                                   curr_x_2d_hit    ;
   wire     [1:0]                                   curr_y_2d_hit    ;
   wire     [1:0]                                   delta_x_2d_hit   ;
   wire     [1:0]                                   delta_y_2d_hit   ;
   
   wire     [1:0]                                   curr_x_2d_read   ;
   wire     [1:0]                                   curr_y_2d_read   ;
   wire     [1:0]                                   delta_x_2d_read  ;
   wire     [1:0]                                   delta_y_2d_read  ;
   
	
    wire    [1:0]                                   delta_x_luma;    // possible 0,1,2
    wire    [1:0]                                   delta_y_luma;    //possible 0,1,2,3   
    wire    [1:0]                                   delta_x_chma; // possible 0,1,2
    wire    [1:0]                                   delta_y_chma; //possible 0,1,2,3

    

    wire    [1:0]                                   curr_x; // possible 0,1,2
    wire    [1:0]                                   curr_y; // possible 0,1,2,3
    
    wire    [1:0]                                   curr_x_2d; // possible 0,1,2
    wire    [1:0]                                   curr_y_2d; // possible 0,1,2,3
    

    reg  [1:0]                                      curr_x_4 ;
    reg  [1:0]                                      curr_y_4 ;


	
    wire    [1:0]                                   curr_x_luma; // possible 0,1,2
    wire    [1:0]                                   curr_y_luma; // possible 0,1,2,3

    wire    [1:0]                                   curr_x_chma; // possible 0,1,2
    wire    [1:0]                                   curr_y_chma; // possible 0,1,2,3

    wire      [X_ADDR_WDTH - C_L_H_SIZE -1: 0]      curr_x_addr;
    wire      [Y_ADDR_WDTH - C_L_V_SIZE -1: 0]      curr_y_addr;

    wire    [SET_ADDR_WDTH -1:0]                    set_addr_2d;
    wire    [SET_ADDR_WDTH -1:0]                    set_addr_read;
    wire    [SET_ADDR_WDTH -1:0]                    set_addr_hit;

    wire    [C_N_WAY-1:0]                           set_idx_d;
    reg     [C_N_WAY-1:0]                           set_idx_2d;
    wire    [C_N_WAY-1:0]                           set_idx_miss;
    wire    [C_N_WAY-1:0]                           set_idx_miss_read;
    wire    [C_N_WAY-1:0]                           set_idx_hit;
	

    reg     [SET_ADDR_WDTH+C_N_WAY-1:0]             cache_w_addr;
    reg     [SET_ADDR_WDTH+C_N_WAY-1:0]             cache_r_addr;
    reg     [SET_ADDR_WDTH+C_N_WAY-1:0]             cache_addr;
    wire    [BIT_DEPTH*CACHE_LINE_WDTH-1:0]         cache_rdata;
    reg                                             cache_wr_en;

    wire     luma_dest_enable_reg;
    reg      luma_dest_enable_reg_d;
    wire     luma_dest_enable_reg_read;
    wire     luma_dest_enable_reg_hit;
    wire     chma_dest_enable_reg;
    reg      chma_dest_enable_reg_d;
    wire     chma_dest_enable_reg_read;
    wire     chma_dest_enable_reg_hit;


	
    wire cur_xy_changed_luma;
    wire cur_xy_changed_chma; 
    integer i,j;          
    
    wire    [C_L_H_SIZE-1:0]                        cl_strt_x_luma_2d;
    wire    [C_L_H_SIZE-1:0]                        cl_strt_x_luma_2d_read;
    wire    [C_L_H_SIZE-1:0]                        cl_strt_x_luma_2d_hit;
    wire    [C_L_H_SIZE_C-1:0]                      cl_strt_x_chma_2d;
    wire    [C_L_H_SIZE_C-1:0]                      cl_strt_x_chma_2d_read;
    wire    [C_L_H_SIZE_C-1:0]                      cl_strt_x_chma_2d_hit;
    wire    [C_L_V_SIZE-1:0]                        cl_strt_y_luma_2d;
    wire    [C_L_V_SIZE-1:0]                        cl_strt_y_luma_2d_read;
    wire    [C_L_V_SIZE-1:0]                        cl_strt_y_luma_2d_hit;
    wire    [C_L_V_SIZE_C-1:0]                      cl_strt_y_chma_2d;
    wire    [C_L_V_SIZE_C-1:0]                      cl_strt_y_chma_2d_read;
    wire    [C_L_V_SIZE_C-1:0]                      cl_strt_y_chma_2d_hit;
    
   wire     [LUMA_DIM_WDTH-1:0] dst_strt_x_luma_d;
   wire     [LUMA_DIM_WDTH-1:0] dest_end_x_luma_d;
   wire     [LUMA_DIM_WDTH-1:0] dst_strt_y_luma_d;
   wire     [LUMA_DIM_WDTH-1:0] dest_end_y_luma_d;
    
   wire    [LUMA_DIM_WDTH-1:0] dst_strt_x_luma_d_hit;
   wire    [LUMA_DIM_WDTH-1:0] dest_end_x_luma_d_hit;
   wire    [LUMA_DIM_WDTH-1:0] dst_strt_y_luma_d_hit;
   wire    [LUMA_DIM_WDTH-1:0] dest_end_y_luma_d_hit;

   wire    [LUMA_DIM_WDTH-1:0] dst_strt_x_luma_d_read;
   wire    [LUMA_DIM_WDTH-1:0] dest_end_x_luma_d_read;
   wire    [LUMA_DIM_WDTH-1:0] dst_strt_y_luma_d_read;
   wire    [LUMA_DIM_WDTH-1:0] dest_end_y_luma_d_read;

    
   wire     [CHMA_DIM_WDTH-1:0] dst_strt_x_chma_d;
   wire     [CHMA_DIM_WDTH-1:0] dest_end_x_chma_d;
   wire     [CHMA_DIM_HIGT-1:0] dst_strt_y_chma_d;
   wire     [CHMA_DIM_HIGT-1:0] dest_end_y_chma_d;
    
    wire    [CHMA_DIM_WDTH-1:0] dst_strt_x_chma_d_hit;
    wire    [CHMA_DIM_WDTH-1:0] dest_end_x_chma_d_hit;
    wire    [CHMA_DIM_HIGT-1:0] dst_strt_y_chma_d_hit;
    wire    [CHMA_DIM_HIGT-1:0] dest_end_y_chma_d_hit;
    
    wire    [CHMA_DIM_WDTH-1:0] dst_strt_x_chma_d_read;
    wire    [CHMA_DIM_WDTH-1:0] dest_end_x_chma_d_read;
    wire    [CHMA_DIM_HIGT-1:0] dst_strt_y_chma_d_read;
    wire    [CHMA_DIM_HIGT-1:0] dest_end_y_chma_d_read;

    reg   [C_L_H_SIZE -1:0] 						          dest_fill_x_loc_luma_arry_d[LUMA_REF_BLOCK_WIDTH -1:0];
    reg   [C_L_V_SIZE -1:0] 						          dest_fill_y_loc_luma_arry_d[LUMA_REF_BLOCK_WIDTH -1:0];
    reg   [C_L_V_SIZE + C_L_H_SIZE-1:0] 	                  dest_fill_xy_loc_luma_d[0:LUMA_REF_BLOCK_WIDTH -1][0:LUMA_REF_BLOCK_WIDTH -1];

    
    reg   [LUMA_REF_BLOCK_WIDTH -1:0]                        dest_fill_x_mask_luma_d;
    reg   [LUMA_REF_BLOCK_WIDTH -1:0]                        dest_fill_y_mask_luma_d;

    reg   [C_L_H_SIZE_C -1:0] 								 dest_fill_x_loc_chma_arry_d[CHMA_REF_BLOCK_WIDTH -1:0];
    reg   [C_L_V_SIZE_C -1:0] 								 dest_fill_y_loc_chma_arry_d[CHMA_REF_BLOCK_HIGHT -1:0];
    reg   [C_L_V_SIZE_C + C_L_H_SIZE_C-1:0] 				 dest_fill_xy_loc_chma_d[0:CHMA_REF_BLOCK_HIGHT -1][0:CHMA_REF_BLOCK_WIDTH -1];
	

    reg     [CHMA_REF_BLOCK_WIDTH -1:0]                      dest_fill_x_mask_chma_d		;
    reg     [CHMA_REF_BLOCK_HIGHT -1:0]                      dest_fill_y_mask_chma_d		;

    reg  [BIT_DEPTH-1:0]     block_11x11 [0:LUMA_REF_BLOCK_WIDTH -1][0:LUMA_REF_BLOCK_WIDTH -1];
    
    reg  [BIT_DEPTH-1:0]     block_5x5_cb[0:CHMA_REF_BLOCK_HIGHT -1][0:CHMA_REF_BLOCK_WIDTH -1];
    reg  [BIT_DEPTH-1:0]     block_5x5_cr[0:CHMA_REF_BLOCK_HIGHT -1][0:CHMA_REF_BLOCK_WIDTH -1];

    wire [BIT_DEPTH-1:0] cache_w_data_arr_luma [CACHE_LINE_WDTH-1:0];
    wire [BIT_DEPTH-1:0] cache_w_data_arr_cb   [CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT)-1:0];
    wire [BIT_DEPTH-1:0] cache_w_data_arr_cr   [CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT)-1:0];
	
    wire [BIT_DEPTH-1:0] cache_rdata_arr      [(BIT_DEPTH*CACHE_LINE_WDTH/BIT_DEPTH)-1:0];
    wire [BIT_DEPTH-1:0] cache_rdata_arr_luma [CACHE_LINE_WDTH-1:0];
    wire [BIT_DEPTH-1:0] cache_rdata_arr_cb   [CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT)-1:0];
    wire [BIT_DEPTH-1:0] cache_rdata_arr_cr   [CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT)-1:0];

	
	wire		[CACHE_LINE_WDTH*BIT_DEPTH -1:0]		    cache_w_port;
	reg 		[CACHE_LINE_WDTH*BIT_DEPTH -1:0]		    cache_w_port_d;
	reg 		[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]		    cache_w_port_old1_reg;
	reg 		[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]		    cache_w_port_old2_reg;
	reg 		[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]		    cache_w_port_old3_reg;
	reg 		[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]		    cache_w_port_old4_reg;

	wire    miss_elem_fifo_empty;
	wire    hit_elem_fifo_empty;
	// wire d_miss_elem_fifo_empty;
	// wire  d_hit_elem_fifo_empty;
	wire    miss_elem_fifo_full;
	wire    hit_elem_fifo_full;
	wire    miss_elem_fifo_wr_en;
	reg     miss_elem_fifo_wr_en_d;
	reg     miss_elem_fifo_wr_en_2d;
	wire    hit_elem_fifo_wr_en;
	reg     hit_elem_fifo_wr_en_d;
	reg     hit_elem_fifo_wr_en_2d;
	

	
	wire dest_enable_wire_valid;
	wire tag_compare_stage_ready;
	wire tag_compare_stage_ready_d;

	// reg  miss_idx_fifo_wr_en;
	// wire miss_idx_fifo_empty;
	// wire miss_idx_fifo_full;	
	reg miss_elem_fifo_rd_en;	
	reg miss_elem_fifo_rd_en_d;	
	reg miss_elem_fifo_rd_en_2d;	
	reg  hit_elem_fifo_rd_en;	
	reg  hit_elem_fifo_rd_en_d;	
	reg  hit_elem_fifo_rd_en_2d;	
	
	(* keep = "true", max_fanout = 200 *) reg data_read_stage_valid;
	(* keep = "true", max_fanout = 200 *) reg data_read_hit_valid;
	(* keep = "true", max_fanout = 200 *) reg data_read_mis_valid;
	// reg data_read_stage_ready;
	// reg [2:0] state_data_read_d;
	

	wire last_block_valid_0d;
	wire last_block_valid_2d;
	reg  last_block_valid_3d;
	wire last_block_valid_2d_read;
	wire last_block_valid_2d_hit;
	
	reg							            block_ready_reg;   // assuming cache_block_ready is single cylce
	reg							            block_ready_reg_d;   // assuming cache_block_ready is single cylce
    
    wire         [LUMA_DIM_WDTH-1:0]                 d_block_x_offset_luma;  // starting position as an offset from top left corner
    wire         [LUMA_DIM_WDTH-1:0]                 d_block_y_offset_luma;
    wire         [CHMA_DIM_WDTH-1:0]                 d_block_x_offset_chma;
    wire         [CHMA_DIM_HIGT-1:0]                 d_block_y_offset_chma; 

    wire         [LUMA_DIM_WDTH-1:0]                 d_block_x_end_luma;
    wire         [LUMA_DIM_WDTH-1:0]                 d_block_y_end_luma;
    wire         [CHMA_DIM_WDTH-1:0]                 d_block_x_end_chma;
    wire         [CHMA_DIM_HIGT-1:0]                 d_block_y_end_chma; 
    
    wire [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  luma_ref_start_x  ;
    wire [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  luma_ref_start_y  ;
    wire [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  chma_ref_start_x  ;
    wire [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]  chma_ref_start_y  ;

             
    wire  [LUMA_DIM_WDTH - 1:0]                   chma_ref_width_x;
    wire  [LUMA_DIM_WDTH - 1:0]                   chma_ref_height_y;
    wire  [LUMA_DIM_WDTH - 1:0]                   luma_ref_width_x;
    wire  [LUMA_DIM_WDTH - 1:0]                   luma_ref_height_y;

	
    wire  [MV_C_FRAC_WIDTH_HIGH -1:0]      d_frac_x_out;
    wire  [MV_C_FRAC_WIDTH_HIGH -1:0]      d_frac_y_out;	

	
	

	wire [BIT_DEPTH* LUMA_REF_BLOCK_WIDTH* LUMA_REF_BLOCK_WIDTH -1:0]     block_121_fifo_in;
	wire [BIT_DEPTH* CHMA_REF_BLOCK_HIGHT* CHMA_REF_BLOCK_WIDTH -1:0]     block_25cb_fifo_in;
	wire [BIT_DEPTH* CHMA_REF_BLOCK_HIGHT* CHMA_REF_BLOCK_WIDTH -1:0]     block_25cr_fifo_in;

	
	wire output_fifo_empty;
	wire output_fifo_full;
	// wire output_fifo_almost_full;
	wire output_fifo_almost_full_only;
	wire output_fifo_program_full;
   
	wire op_conf_fifo_empty;
	wire op_conf_fifo_full;
	wire op_conf_fifo_almost_full;
	wire op_conf_fifo_almost_full_only;
	wire op_conf_fifo_program_full;
	wire op_conf_fifo_wr_en;
	reg  op_conf_fifo_rd_en;
   
	wire block_ready_internal;
	// assign cache_valid_out = block_ready_reg & filer_idle_in & miss_elem_fifo_empty;
	
	
	(* mark_debug = "true" *)  wire [BLOCK_NUMBER_WIDTH-1:0] block_number_3;
	(* mark_debug = "true" *)  wire [BLOCK_NUMBER_WIDTH-1:0] block_number_3_hit;
	(* mark_debug = "true" *)  wire [BLOCK_NUMBER_WIDTH-1:0] block_number_3_read;
	(* mark_debug = "true" *)  reg [BLOCK_NUMBER_WIDTH-1:0]  block_number_4;
	
	wire [4:0] output_fifo_data_count;
	wire [4:0] mis_fifo_data_count;
	wire [5:0] hit_fifo_data_count;

    wire is_req_read_core;
    wire is_req_read_mis_in;
    wire is_req_read_mis_out;
    wire ref_pix_axi_ar_valid_fifo_in;
    wire ref_pix_axi_aw_valid_fifo_in;

`ifdef CACHE_TEST		
	integer file_in;
	initial begin
		file_in = $fopen("cache_input_monitor.txt","w") ;
	end
	
	always@(posedge clk) begin
		if(valid_in) begin
			$fwrite(file_in, "%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x,%x\n",
			luma_ref_start_x_in,luma_ref_start_y_in,
			chma_ref_start_x_in,chma_ref_start_y_in,chma_ref_width_x_in,chma_ref_height_y_in,
			luma_ref_width_x_in,luma_ref_height_y_in,ch_frac_x,ch_frac_y,
			ref_idx_in_in,pic_width,pic_height);
		end
	end	
`endif
	


	


    wire [YY_WIDTH-1:0] yy_pixels_8x8;
    parameter Y_DIV_WIDTH = YY_WIDTH/CL_AXI_DIV_FAC;
    parameter CB_DIV_WIDTH = CH_WIDTH/CL_AXI_DIV_FAC;
		
	assign ref_pix_axi_ar_fifo_rd_en    = ref_pix_axi_ar_ready & ref_pix_axi_ar_valid;
	assign ref_pix_axi_ar_valid         = !ref_pix_axi_ar_fifo_empty;
	assign ref_pix_axi_aw_fifo_rd_en    = ref_pix_axi_awready & ref_pix_axi_awvalid;
	assign ref_pix_axi_awvalid          = !ref_pix_axi_aw_fifo_empty;
	assign cache_valid_out              = !output_fifo_empty & filer_idle_in;
	assign block_ready_internal         = block_ready_reg ;
   
    assign cache_w_port = (wb_data_dwnstr_rd_en) ?  (wb_data_dwn_str_rdat[YY_WIDTH-1:0]) : (yy_pixels_8x8) ; 

		
    assign                  ref_pix_axi_ar_size   = `AX_SIZE_64;
    assign                  ref_pix_axi_ar_len    = (CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH;

    assign                  ref_pix_axi_aw_size   = `AX_SIZE_64;
    assign                  ref_pix_axi_aw_len    = (CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH;
    assign                  ref_pix_axi_w_strb    = {(AXI_CACHE_DATA_WDTH/8){1'b1}};

ref_buf_to_axi_write_master
#(
    .SKIP_ADDR_PHASE(1)
)
cache_wb_blk
(
    .clk                 (clk                  )       ,
    .reset               (reset                )       ,
	//fifo interface      
	.fifo_is_empty_in    (wb_data_fifo_empty   )       ,
	.fifo_rd_en_out	     (wb_data_fifo_rd_en   )       ,
	.fifo_data_in	     (wb_data_read         )       ,   
	.dpb_axi_addr_in     (0                    )       ,
    .pic_width_in        (pic_width            )       ,
    .pic_height_in       (pic_height           )       ,
    //axi interface
    .axi_awid            (ref_pix_axi_awid     )       ,   
    .axi_awlen           (ref_pix_axi_awlen    )       ,   
    .axi_awsize          (ref_pix_axi_awsize   )       ,   
    .axi_awburst         (ref_pix_axi_awburst  )       ,   
    .axi_awlock          (ref_pix_axi_awlock   )       ,   
    .axi_awcache         (ref_pix_axi_awcache  )       ,   
    .axi_awprot          (ref_pix_axi_awprot   )       ,   
    .axi_awvalid         (  )       ,
    .axi_awaddr          (   )       ,
    .axi_awready         (1'b1  )       ,
    .axi_wstrb           (ref_pix_axi_wstrb    )       ,
    .axi_wlast           (ref_pix_axi_wlast    )       ,
    .axi_wvalid          (ref_pix_axi_wvalid   )       ,
    .axi_wdata           (ref_pix_axi_wdata    )       ,
    .axi_wready          (ref_pix_axi_wready   )       ,
    .axi_bid             (ref_pix_axi_bid      )       ,
    .axi_bresp           (ref_pix_axi_bresp    )       ,
    .axi_bvalid          (ref_pix_axi_bvalid   )       ,
    .axi_bready          (ref_pix_axi_bready   )
);
    

    num_val_clines_generator num_val_clines_block_luma (
    .start_x_in(start_x_in[C_L_H_SIZE+LUMA_DIM_WDTH-1:0]), 
    .start_y_in(start_y_in[C_L_V_SIZE+LUMA_DIM_WDTH-1:0]), 
    .rf_blk_wdt_in(rf_blk_wdt_in), 
    .rf_blk_hgt_in(rf_blk_hgt_in), 
    .delta_x_out(delta_x_luma), 
    .delta_y_out(delta_y_luma)
    );
    
    
    num_val_clines_generator_ch num_val_clines_block_chma (
    .start_x_in(start_x_ch[C_L_H_SIZE_C+CHMA_DIM_WDTH-1:0]), 
    .start_y_in(start_y_ch[C_L_V_SIZE_C+CHMA_DIM_HIGT-1:0]), 
    .rf_blk_wdt_in(rf_blk_wdt_ch), 
    .rf_blk_hgt_in(rf_blk_hgt_ch), 
    .delta_x_out(delta_x_chma), 
    .delta_y_out(delta_y_chma)
    );

    num_val_clines_generator num_val_clines_block_great (
    .start_x_in(start_great_x_in[C_L_H_SIZE+LUMA_DIM_WDTH-1:0]), 
    .start_y_in(start_great_y_in[C_L_V_SIZE+LUMA_DIM_WDTH-1:0]), 
    .rf_blk_wdt_in(rf_blk_great_wdt_in), 
    .rf_blk_hgt_in(rf_blk_great_hgt_in), 
    .delta_x_out(delta_x), 
    .delta_y_out(delta_y)
    );

  

    cache_data_mem cache_mem_block(
    .clk(clk), 
    // .w_addr_in(cache_w_addr), 
    // .r_addr_in(cache_r_addr), 
    .addr_in(cache_addr), 
    .r_data_out(cache_rdata), 
    .w_data_in(cache_w_port[CACHE_LINE_WDTH*BIT_DEPTH -1:0]), 
    .w_en_in(cache_wr_en)
    );

   geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(3),
        .FIFO_DATA_WIDTH(
			AXI_ADDR_WDTH
		)
    ) miss_raddr_fifo (
        .clk(clk), 
        .reset(reset), 
        .wr_en(ref_pix_axi_ar_valid_fifo_in), 
        .rd_en(ref_pix_axi_ar_fifo_rd_en), 
        .d_in({
			ref_pix_axi_ar_addr_fifo_in
		}), 
        .d_out({	
			ref_pix_axi_ar_addr
		}), 
		// .d_empty(d_miss_elem_fifo_empty),
        .empty(ref_pix_axi_ar_fifo_empty), 
        .program_full(ref_pix_axi_ar_fifo_full),
        .almost_full(),
        .full()
        );	
        
   geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(3),
        .FIFO_DATA_WIDTH(
			AXI_ADDR_WDTH
		)
    ) miss_waddr_fifo (
        .clk(clk), 
        .reset(reset), 
        .wr_en(ref_pix_axi_aw_valid_fifo_in), 
        .rd_en(ref_pix_axi_aw_fifo_rd_en), 
        .d_in({
			ref_pix_axi_ar_addr_fifo_in
		}), 
        .d_out({	
			ref_pix_axi_awaddr
		}), 
		// .d_empty(d_miss_elem_fifo_empty),
        .empty(ref_pix_axi_aw_fifo_empty), 
        .program_full(ref_pix_axi_aw_fifo_full),
        .almost_full(),
        .full()
        );	
		
		
	
       geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(MIS_FIFO_DEPTH),
      .FIFO_DATA_WIDTH(1+2*4+ BLOCK_NUMBER_WIDTH +1+1+1+ C_N_WAY + CHMA_DIM_WDTH * 2 + CHMA_DIM_HIGT * 2 + LUMA_DIM_WDTH* 4 + SET_ADDR_WDTH  + C_L_H_SIZE + C_L_V_SIZE + C_L_H_SIZE_C + C_L_V_SIZE_C)
      ) miss_elem_fifo (
        .clk(clk), 
        .reset(reset), 
        .wr_en(miss_elem_fifo_wr_en), 
        .rd_en(miss_elem_fifo_rd_en), 
        .d_in({
         is_req_read_mis_in,   
         curr_x_2d    ,
         curr_y_2d    ,
         delta_x_2d   ,
         delta_y_2d   ,
        
        
        block_number_3,
        set_idx_miss,
        last_block_valid_2d,
        luma_dest_enable_reg,
        chma_dest_enable_reg,
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
        dest_end_y_chma_d,
        set_addr_2d
		
		}), 
        .d_out({
         is_req_read_mis_out,
         curr_x_2d_read    ,
         curr_y_2d_read    ,
         delta_x_2d_read   ,
         delta_y_2d_read   ,
        
        
        block_number_3_read,
        set_idx_miss_read,
        last_block_valid_2d_read,
        luma_dest_enable_reg_read,
        chma_dest_enable_reg_read,
        cl_strt_x_luma_2d_read,
        cl_strt_x_chma_2d_read,
        cl_strt_y_luma_2d_read,
        cl_strt_y_chma_2d_read,
        dst_strt_x_luma_d_read,
        dest_end_x_luma_d_read,
        dst_strt_y_luma_d_read,
        dest_end_y_luma_d_read,
        dst_strt_x_chma_d_read,
        dest_end_x_chma_d_read,
        dst_strt_y_chma_d_read,
        dest_end_y_chma_d_read,
        set_addr_read		
			
		}), 
		// .d_empty(d_miss_elem_fifo_empty),
        .empty(miss_elem_fifo_empty), 
        .program_full(miss_elem_fifo_full),
		  .almost_full(),
        .full()
        );

       geet_fifo_almost_full #(
         .LOG2_FIFO_DEPTH(HIT_FIFO_DEPTH),
         .FIFO_DATA_WIDTH(2*4 + BLOCK_NUMBER_WIDTH +1+1+1+ C_N_WAY + CHMA_DIM_WDTH * 2 + CHMA_DIM_HIGT * 2+ LUMA_DIM_WDTH* 4 + SET_ADDR_WDTH  + C_L_H_SIZE + C_L_V_SIZE + C_L_H_SIZE_C + C_L_V_SIZE_C)
      ) hit_elem_fifo (
        .clk(clk), 
        .reset(reset), 
        .wr_en(hit_elem_fifo_wr_en), 
        .rd_en(hit_elem_fifo_rd_en), 
        .d_in({
        
        curr_x_2d    ,
        curr_y_2d    ,
        delta_x_2d   ,
        delta_y_2d   ,
        block_number_3,
        set_idx_d,
        last_block_valid_2d,
        luma_dest_enable_reg,
        chma_dest_enable_reg,
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
        dest_end_y_chma_d,
        set_addr_2d
		
		}), 
        .d_out({
        
         curr_x_2d_hit    ,
         curr_y_2d_hit    ,
         delta_x_2d_hit   ,
         delta_y_2d_hit   ,
        
        block_number_3_hit,
        set_idx_hit,
        last_block_valid_2d_hit,
        luma_dest_enable_reg_hit,
        chma_dest_enable_reg_hit,
        cl_strt_x_luma_2d_hit,
        cl_strt_x_chma_2d_hit,
        cl_strt_y_luma_2d_hit,
        cl_strt_y_chma_2d_hit,
        dst_strt_x_luma_d_hit,
        dest_end_x_luma_d_hit,
        dst_strt_y_luma_d_hit,
        dest_end_y_luma_d_hit,
        dst_strt_x_chma_d_hit,
        dest_end_x_chma_d_hit,
        dst_strt_y_chma_d_hit,
        dest_end_y_chma_d_hit,
        set_addr_hit
		}), 
		// .d_empty(d_hit_elem_fifo_empty),
        .empty(hit_elem_fifo_empty), 
        .program_full(hit_elem_fifo_full),
        .almost_full(),
        .full()
        );            						


   
   always@(*) begin
      op_conf_fifo_rd_en = cache_valid_out;
   end


                  
       geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(OUT_FIFO_DEPTH),
        .FIFO_DATA_WIDTH(
			(MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH )  						+
			(MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH )  						+
			(MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH )  						+
			(MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH )  						+
			(LUMA_DIM_WDTH )                   							+
			(LUMA_DIM_WDTH )                   							+
			(LUMA_DIM_WDTH )                   							+
			(LUMA_DIM_WDTH )                   							+
			(MV_C_FRAC_WIDTH_HIGH )      								+
			(MV_C_FRAC_WIDTH_HIGH )      								+
			(LUMA_DIM_WDTH)                 							+
			(LUMA_DIM_WDTH)                 							+
			(CHMA_DIM_HIGT)                 							+
			(CHMA_DIM_WDTH)                 							+
			(LUMA_DIM_WDTH)                 							+
			(LUMA_DIM_WDTH)                 							+
			(CHMA_DIM_HIGT)                 							+
			(CHMA_DIM_WDTH)     		
		
		)
    ) output_fifo_rest (
        .clk(clk), 
        .reset(reset), 
        .wr_en(op_conf_fifo_wr_en), 
        .rd_en(op_conf_fifo_rd_en), 
        .d_in({
				luma_ref_start_x   ,
				luma_ref_start_y   ,
				chma_ref_start_x   ,
				chma_ref_start_y   ,
				chma_ref_width_x   ,
				chma_ref_height_y  ,
				luma_ref_width_x   ,
				luma_ref_height_y  ,
				d_frac_x_out,
				d_frac_y_out,
				d_block_x_offset_luma,
				d_block_y_offset_luma,
				d_block_x_offset_chma,
				d_block_y_offset_chma,
				d_block_x_end_luma,
				d_block_y_end_luma,
				d_block_x_end_chma,
				d_block_y_end_chma
			}),
        .d_out({
				luma_ref_start_x_out   ,
				luma_ref_start_y_out   ,
				chma_ref_start_x_out   ,
				chma_ref_start_y_out   ,
				chma_ref_width_x_out   ,
				chma_ref_height_y_out  ,
				luma_ref_width_x_out   ,
				luma_ref_height_y_out  ,
				ch_frac_x_out,
				ch_frac_y_out,
				block_x_offset_luma,
				block_y_offset_luma,
				block_x_offset_chma,
				block_y_offset_chma,
				block_x_end_luma,
				block_y_end_luma,
				block_x_end_chma,
				block_y_end_chma
			}),
      .full(op_conf_fifo_full),
		.almost_full(op_conf_fifo_almost_full_only),
		.program_full(op_conf_fifo_program_full),
        .empty(op_conf_fifo_empty)
        );	
        
      assign   op_conf_fifo_almost_full = op_conf_fifo_almost_full_only | op_conf_fifo_full;
      wire op_luma_program_full;
       geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(3),
        .FIFO_DATA_WIDTH(
			(BIT_DEPTH* LUMA_REF_BLOCK_WIDTH* LUMA_REF_BLOCK_WIDTH ) 
		
		)
    ) output_fifo_luma (
        .clk(clk), 
        .reset(reset), 
        .wr_en(block_ready_internal), 
        .rd_en(cache_valid_out), 
        .d_in({
				block_121_fifo_in
			}),
        .d_out({
				luma_ref_block_out
			}),
        .empty(output_fifo_empty), 
        .full(output_fifo_full),
        .almost_full(output_fifo_almost_full_only),
        .program_full(op_luma_program_full)
        );	
        
       geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(3),
        .FIFO_DATA_WIDTH(
			(BIT_DEPTH* CHMA_REF_BLOCK_HIGHT* CHMA_REF_BLOCK_WIDTH )   	+
			(BIT_DEPTH* CHMA_REF_BLOCK_HIGHT* CHMA_REF_BLOCK_WIDTH )   
		
		)) 
      output_fifo_chma (
        .clk(clk), 
        .reset(reset), 
        .wr_en(block_ready_internal), 
        .rd_en(cache_valid_out), 
        .d_in({
				block_25cb_fifo_in,
				block_25cr_fifo_in
			}),
        .d_out({
				cb_ref_block_out,
				cr_ref_block_out
			}),
        .empty(),
        .program_full(),
        .almost_full(),
        .full()
        );	
        
    geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(7),
        .FIFO_DATA_WIDTH( YY_WIDTH+CH_WIDTH*2 )
    ) wb_data_buffer_upstr (
        .clk(clk), 
        .reset(reset), 
        .wr_en((valid_in &  (~is_req_read) & cache_idle_out)), 
        .rd_en(wb_data_fifo_rd_en), 
        .d_in({wb_data_in}),
        .d_out({ wb_data_read }),
        .empty(wb_data_fifo_empty), 
        .full( ),
        .almost_full(wb_data_fifo_full),
        .program_full()
        );	
    
    geet_fifo_almost_full #(
		.LOG2_FIFO_DEPTH(7),
        .FIFO_DATA_WIDTH( YY_WIDTH+CH_WIDTH*2 )
    ) wb_data_buffer_dwnstr (
        .clk(clk), 
        .reset(reset), 
        .wr_en((wb_data_fifo_rd_en)), 
        .rd_en(wb_data_dwnstr_rd_en & ~wb_data_dwnstr_fifo_empty), 
        .d_in({wb_data_read}),
        .d_out({ wb_data_dwn_str_rdat }),
        .empty(wb_data_dwnstr_fifo_empty), 
        .full( ),
        .almost_full(wb_data_dwnstr_fifo_full),
        .program_full()
        );	
     
	assign output_fifo_program_full = output_fifo_almost_full_only | output_fifo_full | op_luma_program_full;		  

	
	assign cache_full_idle = hit_elem_fifo_empty & miss_elem_fifo_empty & output_fifo_empty                       & !block_ready_reg_d  & !data_read_stage_valid & !hit_elem_fifo_wr_en_d & !miss_elem_fifo_wr_en_d & !hit_elem_fifo_wr_en_2d & !miss_elem_fifo_wr_en_2d & !hit_elem_fifo_rd_en & !hit_elem_fifo_rd_en_d & !hit_elem_fifo_rd_en_2d & !miss_elem_fifo_rd_en & !miss_elem_fifo_rd_en_d & !miss_elem_fifo_rd_en_2d & (~set_input_stage_valid);

   assign                  ref_pix_axi_ar_burst  = `AX_BURST_INC;
   assign                  ref_pix_axi_ar_prot   = `AX_PROT_DATA;   
   assign                  ref_pix_axi_aw_burst  = `AX_BURST_INC;
   assign                  ref_pix_axi_aw_prot   = `AX_PROT_DATA; 
   
    always@(posedge clk) begin
      hit_elem_fifo_wr_en_d <= hit_elem_fifo_wr_en;
      miss_elem_fifo_wr_en_d <= miss_elem_fifo_wr_en;
      hit_elem_fifo_wr_en_2d <= hit_elem_fifo_wr_en_d;
      miss_elem_fifo_wr_en_2d <= miss_elem_fifo_wr_en_d;
      miss_elem_fifo_rd_en_d <= miss_elem_fifo_rd_en;
      hit_elem_fifo_rd_en_d <= hit_elem_fifo_rd_en;
      miss_elem_fifo_rd_en_2d <= miss_elem_fifo_rd_en_d;
      hit_elem_fifo_rd_en_2d <= hit_elem_fifo_rd_en_d;
    end
    
   always@(*) begin
      ref_pix_axi_r_ready = 0;
		if(!output_fifo_program_full) begin
         if(!ref_pix_axi_r_last) begin
            ref_pix_axi_r_ready = 1;
         end
			else if(!hit_elem_fifo_empty) begin
				if( (block_number_3_hit == block_number_4) & (curr_x_4 == curr_x_2d_hit) & (curr_y_4 == curr_y_2d_hit)) begin // check if next curr_xy need to be added here 
					ref_pix_axi_r_ready = 0;
				end
				else begin
                    if(wb_data_dwnstr_rd_en) begin
                        ref_pix_axi_r_ready = 0;
                    end
                    else begin
                        ref_pix_axi_r_ready = 1;
                    end
				end
			end else begin
                if(wb_data_dwnstr_rd_en) begin
                    ref_pix_axi_r_ready = 0;
                end
                else begin
                    ref_pix_axi_r_ready = 1;
                end
			end
		end
	end


		
    
        

                        
	assign cache_idle_out =  tag_compare_stage_ready & 
                              ~miss_elem_fifo_full &  ~ref_pix_axi_ar_fifo_full 
							 // (!set_input_stage_valid		)&(!dest_enable_wire_valid    )&(!tag_compare_stage_valid   );
                             & ~wb_data_fifo_full
							  & (set_input_ready) ;//& (!set_input_stage_valid		);//&(!dest_enable_wire_valid    ); 






cache_conf_stage cache_config_update_block
(
   .clk                        (clk                        ),
   .reset                      (reset                      ),
   
   .valid_in                   (valid_in & cache_idle_out  ),
   .is_req_read                (is_req_read                 ),
   .tag_compare_stage_ready    (tag_compare_stage_ready    ),
   .op_conf_fifo_wr_en         (op_conf_fifo_wr_en         ),
   
   .pic_width                  (pic_width                  ),
   .pic_height                 (pic_height                 ),

   .ref_idx_in                 (ref_idx_in                 ),

   .luma_ref_start_x           (luma_ref_start_x           ),
   .luma_ref_start_y           (luma_ref_start_y           ),
   .chma_ref_start_x           (chma_ref_start_x           ),
   .chma_ref_start_y           (chma_ref_start_y           ),
   .chma_ref_width_x           (chma_ref_width_x           ),
   .chma_ref_height_y          (chma_ref_height_y          ),
   .luma_ref_width_x           (luma_ref_width_x           ),
   .luma_ref_height_y          (luma_ref_height_y          ),
   .d_frac_x_out               (d_frac_x_out               ),
   .d_frac_y_out               (d_frac_y_out               ),
   

   .ref_idx_in_in              (ref_idx_in_in              ),

   .luma_ref_start_x_in        (luma_ref_start_x_in        ),
   .luma_ref_start_y_in        (luma_ref_start_y_in        ),
   .chma_ref_start_x_in        (chma_ref_start_x_in        ),
   .chma_ref_start_y_in        (chma_ref_start_y_in        ),
   .chma_ref_width_x_in        (chma_ref_width_x_in        ),
   .chma_ref_height_y_in       (chma_ref_height_y_in       ),
   .luma_ref_width_x_in        (luma_ref_width_x_in        ),
   .luma_ref_height_y_in       (luma_ref_height_y_in       ),
   .ch_frac_x                  (ch_frac_x                  ),
   .ch_frac_y                  (ch_frac_y                  ), 
   
   .start_x_in                 (start_x_in                 ),
   .start_y_in                 (start_y_in                 ),
   .start_x_ch                 (start_x_ch                 ),
   .start_y_ch                 (start_y_ch                 ),
   .rf_blk_wdt_in              (rf_blk_wdt_in              ),
   .rf_blk_hgt_in              (rf_blk_hgt_in              ),
   .rf_blk_wdt_ch              (rf_blk_wdt_ch              ),
   .rf_blk_hgt_ch              (rf_blk_hgt_ch              ),
   .rf_blk_great_wdt_in        (rf_blk_great_wdt_in        ),
   .rf_blk_great_hgt_in        (rf_blk_great_hgt_in        ),
   .start_great_x_in           (start_great_x_in           ),
   .start_great_y_in           (start_great_y_in           ),
   .d_block_x_end_luma         (d_block_x_end_luma         ),
   .d_block_y_end_luma         (d_block_y_end_luma         ),
   .d_block_x_offset_luma      (d_block_x_offset_luma      ),
   .d_block_y_offset_luma      (d_block_y_offset_luma      ),
   .d_block_x_end_chma         (d_block_x_end_chma         ),
   .d_block_y_end_chma         (d_block_y_end_chma         ),
   .d_block_x_offset_chma      (d_block_x_offset_chma      ),
   .d_block_y_offset_chma      (d_block_y_offset_chma      )
   
   
);


cache_set_input cache_set_input_block
(
   .clk                       (clk                       ) ,
   .reset                     (reset                     ) ,
   
   .valid_in                  (valid_in &   cache_idle_out  ) ,
   .is_req_read_in            (is_req_read                  ) ,
   .set_input_stage_valid     (set_input_stage_valid     ) ,
   .is_req_read_out           (is_req_read_core          ) ,
   .tag_compare_stage_ready   (tag_compare_stage_ready   ) ,
   .set_input_ready           (set_input_ready           ) ,
   
   .start_great_x_in          (start_great_x_in          ) ,
   .start_great_y_in          (start_great_y_in          ) ,
   .start_x_ch                (start_x_ch                ) ,
   .start_x_in                (start_x_in                ) ,
   .start_y_ch                (start_y_ch                ) ,
   .start_y_in                (start_y_in                ) ,
   
   .rf_blk_hgt_in             (rf_blk_hgt_in             ) ,
   .rf_blk_wdt_in             (rf_blk_wdt_in             ) ,
   .rf_blk_hgt_ch             (rf_blk_hgt_ch             ) ,
   .rf_blk_wdt_ch             (rf_blk_wdt_ch             ) ,

 
   .delta_x                   (delta_x                   ) ,
   .delta_y                   (delta_y                   ) ,
   .delta_x_luma              (delta_x_luma              ) ,
   .delta_x_chma              (delta_x_chma              ) ,
   
   .curr_x_addr               (curr_x_addr               ) ,
   .curr_y_addr               (curr_y_addr               ) ,
   .curr_x_luma               (curr_x_luma               ) ,
   .curr_y_luma               (curr_y_luma               ) ,
   .curr_x_chma               (curr_x_chma               ) ,
   .curr_y_chma               (curr_y_chma               ) ,
   
   .cur_xy_changed_luma       (cur_xy_changed_luma       ) ,
   .cur_xy_changed_chma       (cur_xy_changed_chma       ) ,
   
   // .last_block_valid_0d       (last_block_valid_0d       ) 
   .curr_x                    (curr_x                    ) , 
   .curr_y                    (curr_y                    ) 
   
);

cache_bank_core 
#(.BLOCK_NUMBER_WIDTH(BLOCK_NUMBER_WIDTH))
core_tag_block
(
   .clk                                   (clk                             ),
   .reset                                 (reset                           ),
   .curr_x_luma                           (curr_x_luma                     ),
   .curr_y_luma                           (curr_y_luma                     ),
   
   .curr_x_chma                           (curr_x_chma                     ),
   .curr_y_chma                           (curr_y_chma                     ),
   
   .curr_x                                (curr_x                          ),
   .curr_y                                (curr_y                          ),
   .delta_x                               (delta_x                         ),
   .delta_y                               (delta_y                         ),
 
   .curr_x_2d                             (curr_x_2d                       ),
   .curr_y_2d                             (curr_y_2d                       ),
   .delta_x_2d                            (delta_x_2d                      ),
   .delta_y_2d                            (delta_y_2d                      ),

   .cur_xy_changed_luma                   (cur_xy_changed_luma             ),
   .cur_xy_changed_chma                   (cur_xy_changed_chma             ),
   
   .start_x_in                            (start_x_in                      ),
   .start_y_in                            (start_y_in                      ),
   .start_x_ch                            (start_x_ch                      ),
   .start_y_ch                            (start_y_ch                      ),
   
   .curr_x_addr                           (curr_x_addr                     ),
   .curr_y_addr                           (curr_y_addr                     ),
   .ref_idx_in                            (ref_idx_in                      ),
   
   .d_block_x_offset_luma                 (d_block_x_offset_luma           ),
   .d_block_y_offset_luma                 (d_block_y_offset_luma           ),
   .d_block_x_offset_chma                 (d_block_x_offset_chma           ),
   .d_block_y_offset_chma                 (d_block_y_offset_chma           ),
   
   .rf_blk_hgt_in                         (rf_blk_hgt_in                   ),
   .rf_blk_wdt_in                         (rf_blk_wdt_in                   ),
   .rf_blk_hgt_ch                         (rf_blk_hgt_ch                   ),
   .rf_blk_wdt_ch                         (rf_blk_wdt_ch                   ),
   
   .delta_x_luma                          (delta_x_luma                    ),
   .delta_y_luma                          (delta_y_luma                    ),
   .delta_x_chma                          (delta_x_chma                    ),
   .delta_y_chma                          (delta_y_chma                    ),
   
   .set_input_stage_valid                 (set_input_stage_valid           ),
   .is_req_read_in                        (is_req_read_core                ),
   .last_block_valid_0d                   (last_block_valid_0d             ),
   
   .dest_enable_wire_valid                (dest_enable_wire_valid          ),
   .tag_compare_stage_ready               (tag_compare_stage_ready         ),
   .tag_compare_stage_ready_d             (tag_compare_stage_ready_d       ),
   .ref_pix_axi_ar_valid_fifo_in          (ref_pix_axi_ar_valid_fifo_in    ),
   .ref_pix_axi_aw_valid_fifo_in          ((ref_pix_axi_aw_valid_fifo_in )  ),    // full if either of the fifos full
   .ref_pix_axi_ar_addr_fifo_in           (ref_pix_axi_ar_addr_fifo_in     ),
   .set_addr_2d                           (set_addr_2d                     ),
   .is_req_read_misq                      (is_req_read_mis_in              ),
   .miss_elem_fifo_wr_en                  (miss_elem_fifo_wr_en            ),
   .hit_elem_fifo_wr_en                   (hit_elem_fifo_wr_en             ),
   .last_block_valid_2d                   (last_block_valid_2d             ),
 
   .miss_elem_fifo_full                   (miss_elem_fifo_full             ),
   .ref_pix_axi_ar_fifo_full              (ref_pix_axi_ar_fifo_full        ),
   .ref_pix_axi_aw_fifo_full              ((ref_pix_axi_aw_fifo_full | wb_data_fifo_full )      ),
   .hit_elem_fifo_full                    (hit_elem_fifo_full              ),
   .op_conf_fifo_program_full             (op_conf_fifo_program_full       ),
 
   .block_number_3                        (block_number_3                  ),
   .set_idx_d                             (set_idx_d                       ),
   .luma_dest_enable_reg                  (luma_dest_enable_reg            ),
   .chma_dest_enable_reg                  (chma_dest_enable_reg            ),
   
   .set_idx_miss                          (set_idx_miss                    ),
   
   .cl_strt_x_luma_2d                     (cl_strt_x_luma_2d               ),
   .cl_strt_x_chma_2d                     (cl_strt_x_chma_2d               ),
   .cl_strt_y_luma_2d                     (cl_strt_y_luma_2d               ),
   .cl_strt_y_chma_2d                     (cl_strt_y_chma_2d               ),
   
   .dst_strt_x_luma_d                     (dst_strt_x_luma_d               ),
   .dest_end_x_luma_d                     (dest_end_x_luma_d               ),
   .dst_strt_y_luma_d                     (dst_strt_y_luma_d               ),
   .dest_end_y_luma_d                     (dest_end_y_luma_d               ),
   
   .dst_strt_x_chma_d                     (dst_strt_x_chma_d               ),
   .dest_end_x_chma_d                     (dest_end_x_chma_d               ),
   .dst_strt_y_chma_d                     (dst_strt_y_chma_d               ),
   .dest_end_y_chma_d                     (dest_end_y_chma_d               )


);

always@(posedge clk) begin
   block_ready_reg_d <= block_ready_reg;
end

always@(posedge clk) begin
	if(reset) begin
		block_ready_reg <= 0;  // block ready can now assert in consecutive clock cycles
	end
	else begin
      block_ready_reg <= 1'b0;
      if(data_read_stage_valid & last_block_valid_3d) begin
         block_ready_reg <= 1;
      end
	end
end


always@(*) begin
	for(i=0;i<LUMA_REF_BLOCK_WIDTH; i=i+1) begin
		for(j=0;j<LUMA_REF_BLOCK_WIDTH; j=j+1) begin
			dest_fill_xy_loc_luma_d[i][j] = (dest_fill_y_loc_luma_arry_d[i] * (1<<C_L_H_SIZE) + dest_fill_x_loc_luma_arry_d[j]);
		end
	end
end

   reg [BIT_DEPTH-1:0] cache_arr_luma_mux [CACHE_LINE_WDTH-1:0];
   reg [BIT_DEPTH-1:0] cache_arr_cb_mux   [CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT)-1:0];
   reg [BIT_DEPTH-1:0] cache_arr_cr_mux   [CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT)-1:0];
    
   
always@(*) begin
   if(data_read_hit_valid) begin
      for(i=0;i<CACHE_LINE_WDTH; i=i+1) begin
         cache_arr_luma_mux[i] = cache_rdata_arr_luma[i];
      end
   end
   else begin
      for(i=0;i<CACHE_LINE_WDTH; i=i+1) begin
         cache_arr_luma_mux[i] = cache_w_data_arr_luma[i];
      end   
   end
end

always@(*) begin
   if(data_read_hit_valid) begin
      for(i=0;i<CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT); i=i+1) begin
         cache_arr_cb_mux[i] = cache_rdata_arr_cb[i];
         cache_arr_cr_mux[i] = cache_rdata_arr_cr[i];
      end
   end
   else begin
      for(i=0;i<CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT); i=i+1) begin
         cache_arr_cb_mux[i] = cache_w_data_arr_cb[i];
         cache_arr_cr_mux[i] = cache_w_data_arr_cr[i];
      end   
   end
end

always@(posedge clk) begin

	for(i=0;i<LUMA_REF_BLOCK_WIDTH; i=i+1) begin
		for(j=0;j<LUMA_REF_BLOCK_WIDTH; j=j+1) begin
         if(data_read_stage_valid) begin
            if(luma_dest_enable_reg_d) begin
               if(dest_fill_x_mask_luma_d[j] & dest_fill_y_mask_luma_d[i]) begin
                  block_11x11[i][j] <= cache_arr_luma_mux[ dest_fill_xy_loc_luma_d[i][j]];
               end
            end
         end
		end
	end
	
	for(i=0;i<CHMA_REF_BLOCK_HIGHT; i=i+1) begin
		for(j=0;j<CHMA_REF_BLOCK_WIDTH; j=j+1) begin
			if(data_read_stage_valid) begin
				if(chma_dest_enable_reg_d) begin
					if(dest_fill_x_mask_chma_d[j] & dest_fill_y_mask_chma_d[i]) begin
						block_5x5_cb[i][j] <= cache_arr_cb_mux[(dest_fill_y_loc_chma_arry_d[i] * (1<<C_L_H_SIZE_C) + dest_fill_x_loc_chma_arry_d[j])];
						block_5x5_cr[i][j] <= cache_arr_cr_mux[(dest_fill_y_loc_chma_arry_d[i] * (1<<C_L_H_SIZE_C) + dest_fill_x_loc_chma_arry_d[j])];
					end
				end
			end

		end
	end
end



reg     [LUMA_DIM_WDTH-1:0]         dst_strt_x_luma_2d;
reg     [LUMA_DIM_WDTH-1:0]         dest_end_x_luma_2d;
reg     [LUMA_DIM_WDTH-1:0]         dst_strt_y_luma_2d;
reg     [LUMA_DIM_WDTH-1:0]         dest_end_y_luma_2d;
                                    
reg     [CHMA_DIM_WDTH-1:0]         dst_strt_x_chma_2d;
reg     [CHMA_DIM_WDTH-1:0]         dest_end_x_chma_2d;
reg     [CHMA_DIM_HIGT-1:0]         dst_strt_y_chma_2d;
reg     [CHMA_DIM_HIGT-1:0]         dest_end_y_chma_2d;

reg    [C_L_H_SIZE-1:0]             cl_strt_x_luma_3d;
reg    [C_L_V_SIZE-1:0]             cl_strt_y_luma_3d;
reg    [C_L_H_SIZE_C-1:0]           cl_strt_x_chma_3d;
reg    [C_L_V_SIZE_C-1:0]           cl_strt_y_chma_3d;

always@(*) begin
   if((block_number_4 == block_number_3_hit) & (curr_x_4 == curr_x_2d_hit) & (curr_y_4 == curr_y_2d_hit) & (~hit_elem_fifo_empty)) begin
      dst_strt_x_luma_2d = dst_strt_x_luma_d_hit;
      dest_end_x_luma_2d = dest_end_x_luma_d_hit;
      dst_strt_y_luma_2d = dst_strt_y_luma_d_hit;
      dest_end_y_luma_2d = dest_end_y_luma_d_hit;
      
      dst_strt_x_chma_2d = dst_strt_x_chma_d_hit;
      dest_end_x_chma_2d = dest_end_x_chma_d_hit;
      dst_strt_y_chma_2d = dst_strt_y_chma_d_hit;
      dest_end_y_chma_2d = dest_end_y_chma_d_hit;   

      cl_strt_x_luma_3d = cl_strt_x_luma_2d_hit;
      cl_strt_y_luma_3d = cl_strt_y_luma_2d_hit;
      cl_strt_x_chma_3d = cl_strt_x_chma_2d_hit;
      cl_strt_y_chma_3d = cl_strt_y_chma_2d_hit;
   end
   else begin
      dst_strt_x_luma_2d = dst_strt_x_luma_d_read;
      dest_end_x_luma_2d = dest_end_x_luma_d_read;
      dst_strt_y_luma_2d = dst_strt_y_luma_d_read;
      dest_end_y_luma_2d = dest_end_y_luma_d_read;
      
      dst_strt_x_chma_2d = dst_strt_x_chma_d_read;
      dest_end_x_chma_2d = dest_end_x_chma_d_read;
      dst_strt_y_chma_2d = dst_strt_y_chma_d_read;
      dest_end_y_chma_2d = dest_end_y_chma_d_read;   

      cl_strt_x_luma_3d = cl_strt_x_luma_2d_read;
      cl_strt_y_luma_3d = cl_strt_y_luma_2d_read;
      cl_strt_x_chma_3d = cl_strt_x_chma_2d_read;
      cl_strt_y_chma_3d = cl_strt_y_chma_2d_read;   
   end
end

always@(posedge clk) begin
      for(j=0;j < LUMA_REF_BLOCK_WIDTH; j = j+1) begin // horizontal span
         if((dst_strt_x_luma_2d <= j[LUMA_DIM_WDTH -1:0]) && (j[LUMA_DIM_WDTH -1:0] <= dest_end_x_luma_2d) ) begin
            dest_fill_x_mask_luma_d[j] <= 1;
            dest_fill_x_loc_luma_arry_d[j] <= (j[LUMA_DIM_WDTH -1:0] - dst_strt_x_luma_2d) + cl_strt_x_luma_3d;
         end
         else begin
            dest_fill_x_mask_luma_d[j] <= 0;
         end
      end
      for(j=0;j < LUMA_REF_BLOCK_WIDTH; j = j+1) begin // vertical span
         if((dst_strt_y_luma_2d <= j[LUMA_DIM_WDTH -1:0]) && (j[LUMA_DIM_WDTH -1:0] <= dest_end_y_luma_2d)) begin
            dest_fill_y_mask_luma_d[j] <= 1;
            dest_fill_y_loc_luma_arry_d[j] <= (j[LUMA_DIM_WDTH -1:0] - dst_strt_y_luma_2d) + cl_strt_y_luma_3d;
         end
         else begin
            dest_fill_y_mask_luma_d[j] <= 0;
         end
      end

      for(j=0;j < CHMA_REF_BLOCK_WIDTH; j = j+1) begin // horizontal span
         if((dst_strt_x_chma_2d <= j[CHMA_DIM_WDTH -1:0]) && (j[CHMA_DIM_WDTH -1:0] <= dest_end_x_chma_2d) ) begin
            dest_fill_x_mask_chma_d[j] <= 1;
            dest_fill_x_loc_chma_arry_d[j] <= (j[CHMA_DIM_WDTH -1:0] - dst_strt_x_chma_2d) + cl_strt_x_chma_3d;
         end
         else begin
            dest_fill_x_mask_chma_d[j] <= 0;
         end
      end
      for(j=0;j < CHMA_REF_BLOCK_HIGHT; j = j+1) begin // vertical span
         if((dst_strt_y_chma_2d <= j[CHMA_DIM_HIGT -1:0]) && (j[CHMA_DIM_HIGT -1:0] <= dest_end_y_chma_2d)) begin
            dest_fill_y_mask_chma_d[j] <= 1;
            dest_fill_y_loc_chma_arry_d[j] <= (j[CHMA_DIM_HIGT -1:0] - dst_strt_y_chma_2d) + cl_strt_y_chma_3d;
         end
         else begin
            dest_fill_y_mask_chma_d[j] <= 0;
         end
      end

end

reg  [1:0] next_curr_x_4_hit ;
reg  [1:0] next_curr_y_4_hit ;

reg  [1:0] next_curr_x_4_read ;
reg  [1:0] next_curr_y_4_read ;

always@(*) begin
      if(curr_x_4 == delta_x_2d_hit) begin
        next_curr_x_4_hit = 0;
        next_curr_y_4_hit = curr_y_4 + 1'b1;
      end
      else begin
        next_curr_x_4_hit = curr_x_4 + 1'b1;
        next_curr_y_4_hit = curr_y_4;
      end   
end

always@(*) begin
      if(curr_x_4 == delta_x_2d_read) begin
        next_curr_x_4_read = 0;
        next_curr_y_4_read = curr_y_4 + 1'b1;
      end
      else begin
        next_curr_x_4_read = curr_x_4 + 1'b1;
        next_curr_y_4_read = curr_y_4;
      end   
end

always@(posedge clk) begin
	if(reset) begin
		data_read_stage_valid <= 0;
        data_read_hit_valid  <= 0;
        data_read_mis_valid  <= 0;
		block_number_4       <= 0;
        curr_x_4             <= 0;
        curr_y_4             <= 0;  
	end
	else begin
        data_read_mis_valid <= 0;
        data_read_hit_valid <= 0;
        data_read_stage_valid <= 0;
        if(!output_fifo_program_full ) begin
            if((!hit_elem_fifo_empty) & (block_number_4 == block_number_3_hit) & (curr_x_4 == curr_x_2d_hit) & (curr_y_4 == curr_y_2d_hit)) begin                  

                if((curr_x_4 == delta_x_2d_hit) && (curr_y_4 == delta_y_2d_hit)) begin
                    last_block_valid_3d <= 1;
                    curr_x_4 <= 0;
                    curr_y_4 <= 0;
                    block_number_4 <= block_number_4 + 1;
                end
                else begin
                    last_block_valid_3d <= 0;
                    curr_x_4 <= next_curr_x_4_hit;
                    curr_y_4 <= next_curr_y_4_hit;
                end
                    data_read_stage_valid <= 1;
                    data_read_hit_valid <= 1;

                    luma_dest_enable_reg_d <= luma_dest_enable_reg_hit;
                    chma_dest_enable_reg_d <= chma_dest_enable_reg_hit;
						
            end
            else if((!miss_elem_fifo_empty) & (block_number_4 == block_number_3_read) & (curr_x_4 == curr_x_2d_read) & (curr_y_4 == curr_y_2d_read) & 
                ((ref_pix_axi_r_valid & ref_pix_axi_r_ready & ref_pix_axi_r_last ) | | (wb_data_dwnstr_rd_en & ~wb_data_dwnstr_fifo_empty)))begin
                    data_read_stage_valid <= is_req_read_mis_out;
                    if((curr_x_4 == delta_x_2d_read) && (curr_y_4 == delta_y_2d_read)) begin
                     last_block_valid_3d <= 1;
                     curr_x_4 <= 0;
                     curr_y_4 <= 0;
                     block_number_4 <= block_number_4 + 1;
                  end
                  else begin
                     last_block_valid_3d <= 0;
                     curr_x_4 <= next_curr_x_4_read;
                     curr_y_4 <= next_curr_y_4_read;
                  end
                data_read_mis_valid <= 1;
                luma_dest_enable_reg_d <= luma_dest_enable_reg_read;
                chma_dest_enable_reg_d <= chma_dest_enable_reg_read;
            end
        end
		
	end
end

// always@(posedge clk) begin
   // if(data_read_mis_valid) begin
      // $display("%d miss",$time);
   // end
   // else if(data_read_hit_valid) begin
      // $display("%d hit",$time);
   // end
// end

always@(posedge clk) begin
    if( (ref_pix_axi_r_valid & ref_pix_axi_r_ready & ref_pix_axi_r_last ) | 
        ( wb_data_dwnstr_rd_en & ~wb_data_dwnstr_fifo_empty))begin
        cache_w_port_d <= cache_w_port;
    end
end


always@(*) begin
    cache_wr_en = 0;
    cache_addr = {set_addr_hit,set_idx_hit};
	if((ref_pix_axi_r_valid & ref_pix_axi_r_ready & ref_pix_axi_r_last) |  ( wb_data_dwnstr_rd_en & ~wb_data_dwnstr_fifo_empty)
        )begin
        cache_wr_en = 1;
        cache_addr = {set_addr_read,set_idx_miss_read};	
	end	
end

// always@(*) begin
    // cache_wr_en = 0;
    // cache_w_addr = {(SET_ADDR_WDTH+C_N_WAY) {1'bx}};	
	// if(ref_pix_axi_r_valid & ref_pix_axi_r_ready) begin
		// if(ref_pix_axi_r_last) begin
			// cache_wr_en = 1;
			// cache_w_addr = {set_addr_read,set_idx_miss_read};	
		// end	
	// end	
// end

always@(*) begin
	// cache_r_addr = {(SET_ADDR_WDTH+C_N_WAY) {1'bx}};
	hit_elem_fifo_rd_en = 0;
	if(!output_fifo_program_full ) begin
        if((!hit_elem_fifo_empty) & (block_number_4 == block_number_3_hit) & (curr_x_4 == curr_x_2d_hit) & (curr_y_4 == curr_y_2d_hit)) begin
            hit_elem_fifo_rd_en = 1;
        end
    end
end	


always@(*) begin
	miss_elem_fifo_rd_en = 0;
    if(!output_fifo_program_full ) begin
        if((!miss_elem_fifo_empty) & (block_number_4 == block_number_3_read) & (curr_x_4 == curr_x_2d_read) & (curr_y_4 == curr_y_2d_read) & 
         ( (ref_pix_axi_r_valid & ref_pix_axi_r_ready & ref_pix_axi_r_last ) | (wb_data_dwnstr_rd_en & ~wb_data_dwnstr_fifo_empty))
            )begin
            miss_elem_fifo_rd_en = 1;
        end
    end
end	


assign wb_data_dwnstr_rd_en = ( ( (block_number_3_read == block_number_4) & (curr_x_4 == curr_x_2d_read) & (curr_y_4 == curr_y_2d_read) ) & (~miss_elem_fifo_empty & ~is_req_read_mis_out) );


always@(posedge clk) begin
    if(ref_pix_axi_r_valid & ref_pix_axi_r_ready) begin
        cache_w_port_old4_reg	<= cache_w_port_old3_reg[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]	    ;
        cache_w_port_old3_reg	<= cache_w_port_old2_reg[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]	    ;
        cache_w_port_old2_reg	<= cache_w_port_old1_reg[(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]	    ;
        cache_w_port_old1_reg	<= ref_pix_axi_r_data   [(CACHE_LINE_WDTH*BIT_DEPTH + (((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)) ) /(((CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH)+1) -1:0]	    ;
    end
end

    generate
        genvar ii;
        genvar jj;
        
        for(jj=0;jj <LUMA_REF_BLOCK_WIDTH ; jj=jj+1 ) begin : row_iteration
            for(ii=0 ; ii < LUMA_REF_BLOCK_WIDTH ; ii = ii+1) begin : column_iteration
                assign  block_121_fifo_in[(jj*LUMA_REF_BLOCK_WIDTH + ii +1)*(BIT_DEPTH)-1: (jj*LUMA_REF_BLOCK_WIDTH + ii)*BIT_DEPTH ] =  block_11x11[jj][ii];
            end
        end
        
        for(jj=0;jj <CHMA_REF_BLOCK_HIGHT ; jj=jj+1 ) begin
            for(ii=0 ; ii < CHMA_REF_BLOCK_WIDTH ; ii = ii+1) begin
                assign    block_25cb_fifo_in[(jj*CHMA_REF_BLOCK_WIDTH + ii +1)*(BIT_DEPTH)-1: (jj*CHMA_REF_BLOCK_WIDTH + ii)*BIT_DEPTH] = block_5x5_cb[jj][ii];
            end
        end
        
        for(jj=0;jj <CHMA_REF_BLOCK_HIGHT ; jj=jj+1 ) begin
            for(ii=0 ; ii < CHMA_REF_BLOCK_WIDTH ; ii = ii+1) begin
                assign    block_25cr_fifo_in[(jj*CHMA_REF_BLOCK_WIDTH + ii +1)*(BIT_DEPTH)-1: (jj*CHMA_REF_BLOCK_WIDTH + ii)*BIT_DEPTH] = block_5x5_cr[jj][ii];
            end
        end
 
		for(ii=0;ii < ((CACHE_LINE_WDTH)); ii=ii+1) begin
            assign    cache_w_data_arr_luma[ii] = cache_w_port_d[(CACHE_LINE_LUMA_OFFSET)+BIT_DEPTH*(ii+1)-1:(CACHE_LINE_LUMA_OFFSET)+BIT_DEPTH*ii];
        end
		// for(ii=0;ii < ((CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT))); ii=ii+1) begin
            // assign    cache_w_data_arr_cb[ii] = cache_w_port_d[(CACHE_LINE_CB_OFFSET)+BIT_DEPTH*(ii+1)-1:(CACHE_LINE_CB_OFFSET)+BIT_DEPTH*ii];
            // assign    cache_w_data_arr_cr[ii] = cache_w_port_d[(CACHE_LINE_CR_OFFSET)+BIT_DEPTH*(ii+1)-1:(CACHE_LINE_CR_OFFSET)+BIT_DEPTH*ii];
        // end
		
        for(ii=0; ii<(BIT_DEPTH*CACHE_LINE_WDTH/BIT_DEPTH) ; ii=ii+1) begin
            assign    cache_rdata_arr[ii] = cache_rdata[BIT_DEPTH*(ii+1)-1:BIT_DEPTH*ii];
        end
		for(ii=0;ii < ((CACHE_LINE_WDTH)); ii=ii+1) begin
            assign    cache_rdata_arr_luma[ii] = cache_rdata[(CACHE_LINE_LUMA_OFFSET)+BIT_DEPTH*(ii+1)-1:(CACHE_LINE_LUMA_OFFSET)+BIT_DEPTH*ii];
        end
		// for(ii=0;ii < ((CACHE_LINE_WDTH/(C_SUB_WIDTH*C_SUB_HEIGHT))); ii=ii+1) begin
            // assign    cache_rdata_arr_cb[ii] = cache_rdata[(CACHE_LINE_CB_OFFSET)+BIT_DEPTH*(ii+1)-1:(CACHE_LINE_CB_OFFSET)+BIT_DEPTH*ii];
            // assign    cache_rdata_arr_cr[ii] = cache_rdata[(CACHE_LINE_CR_OFFSET)+BIT_DEPTH*(ii+1)-1:(CACHE_LINE_CR_OFFSET)+BIT_DEPTH*ii];
        // end

		
    endgenerate


	generate  
		if(C_SIZE == 13) begin
            if(CL_AXI_DIV_FAC==2) begin
                assign  {yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]} = cache_w_port_old1_reg;
                assign  {yy_pixels_8x8[Y_DIV_WIDTH*2-1:Y_DIV_WIDTH*1]} = ref_pix_axi_r_data;  
            end
            else begin
                assign  {yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]} = ref_pix_axi_r_data;     
            end
			// assign cache_w_port = {ref_pix_axi_r_data[CACHE_LINE_WDTH*BIT_DEPTH -1:AXI_CACHE_DATA_WDTH/2],ref_pix_axi_r_data[CACHE_LINE_WDTH*BIT_DEPTH/2 -1:0]};
        end
		else begin
			// assign cache_w_port = ref_pix_axi_r_data[CACHE_LINE_WDTH*BIT_DEPTH -1:0];
            assign {yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]} = ref_pix_axi_r_data;	
		end
	endgenerate

endmodule
