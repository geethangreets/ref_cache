`include "format_def.v"
//`define BIT_DEPTH_8
// `define BIT_DEPTH_10
// `define BIT_DEPTH_12
//`define DEF_CH_TYPE_420
// `define DEF_CH_TYPE_422
//`define DEF_CH_TYPE_444
//`define EN_INTRA_PRED_MONITOR
`define READ_FILE
//`define CABAC_ADDED
//`define SYNTHESIZABLE
// `define CHIPSCOPE_DEBUG
//`define CACHE_FIFOS
//`define SAO_BIG_ERRORS
 // `define CACHE_HARD_DEBUG
 `define HEVC_4K
 
// `define RUN_ABOVE_20
`define INTER_PL_PIPE
//`define HASH_DUMP
//`define INTER_PL_TEST
`ifndef SYNTHESIZABLE
	`define SOFT_MEM_SLAVE
    //`define VERIFY_NONE
	`define MORE_DDR_READ_DELAY
	//`define DISPLAY_BUF_ADDED   // only affectes system_top module, where display_buffer dummy is instantiated.
	// `define DBF_DISCONNECTED
	// `define CACHE_TEST
`endif
`define CACHE_PIPE_PIPE_HIT_FIFO
// `define CACHE_PIPE_PIPE
`ifndef CACHE_PIPE_PIPE
// `define CACHE_PIPE
`endif
`ifdef CACHE_FIFOS
	`ifdef HEVC_4K
			`define CACHE_FIFOS_4K
	`endif
`endif
// `define AXI_INTER_CON_CDC
// `define ETHERNET_ONLY_TEST
// `define DBF_IN_CONFIG_VERIFY
// `define DBF_IN_PIXEL_VERIFY
// `define DBF_IN_BS_VERIFY
`define HEADER_PARAMETERS_0 8'h00
`define HEADER_PARAMETERS_1 8'h01
`define HEADER_PARAMETERS_2 8'h02
`define HEADER_PARAMETERS_3 8'h03
`define HEADER_PARAMETERS_4 8'h04
`define HEADER_PARAMETERS_5 8'h05
`define HEADER_PARAMETERS_6 8'h06
`define HEADER_PARAMETERS_7 8'h07
`define HEADER_SLICE_0 8'h10
`define HEADER_SLICE_1 8'h11
`define HEADER_SLICE_2 8'h12
`define HEADER_SLICE_3 8'h13
`define HEADER_SLICE_4 8'h14
`define HEADER_SLICE_5 8'h15
`define HEADER_SLICE_6 8'h16
`define HEADER_SLICE_7 8'h17
`define HEADER_CTU_0    8'h20
`define HEADER_CTU_1    8'h21
`define HEADER_CTU_2_Y  8'h22
`define HEADER_CTU_2_CB 8'h23
`define HEADER_CTU_2_CR 8'h24
`define HEADER_CTU_3_Y  8'h25
`define HEADER_CTU_3_CB 8'h26
`define HEADER_CTU_3_CR 8'h27
`define HEADER_N_SLICE 8'h15
`define HEADER_N_TILE  8'h16
`define HEADER_CU_0 8'h30
`define HEADER_PU_0 8'h50
`define HEADER_RU_0 8'h40
`define HEADER_RU_1 8'h41
`define HEADER_DU_0 8'h42
`define ST_CURR_BEF  3'd0
`define ST_CURR_AFT  3'd1
`define ST_FOLL      3'd2
`define LT_CURR      3'd3
`define LT_FOLL      3'd4
`define SLICE_B 2'd0
`define SLICE_P 2'd1
`define SLICE_I 2'd2
`define PRED_L0 2'd0
`define PRED_L1 2'd1
`define PRED_BI 2'd2
`define PART_2Nx2N  3'd0
`define PART_2NxN   3'd1
`define PART_Nx2N   3'd2
`define PART_NxN    3'd3
`define PART_2NxnU  3'd4
`define PART_2NxnD  3'd5
`define PART_nLx2N  3'd6
`define PART_nRx2N  3'd7
`define MODE_INTER 1
`define MODE_INTRA 0
`ifdef HEVC_4K
parameter MAX_PIC_WIDTH = 4096;
parameter MAX_PIC_HEIGHT = 4096;
`else
parameter MAX_PIC_WIDTH = 2048;
parameter MAX_PIC_HEIGHT = 2048;
`endif
    parameter                           CTB_SIZE_WIDTH      = 6;
    parameter                           MIN_CTB_SIZE_WIDTH  = 4;
    parameter                           STR_ID_WIDTH        = 8;
    parameter                           STR_LENGTH          = 16;
    parameter                           MAX_STREAMS         = 16;
    parameter                           CB_SIZE_WIDTH = 7;
    parameter                           TB_SIZE_WIDTH = 6;
    parameter                           LOG2_CTB_WIDTH      = 3;
`ifdef HEVC_4K
    parameter                           PIC_DIM_WIDTH       = 12;
`else
	parameter                           PIC_DIM_WIDTH       = 11;
`endif
    parameter                           LOG2_MIN_COLLOCATE_SIZE = 4;
    parameter                           DBF_SAMPLE_XY_ADDR = 3;
	localparam HEADER_WIDTH =  8;
	localparam PIC_WIDTH_WIDTH =  12;
	localparam PIC_HEIGHT_WIDTH =  12;
	localparam LOG2CTBSIZEY_WIDTH =  3;
	localparam PPS_CB_QP_OFFSET_WIDTH = 5;
	localparam PPS_CR_QP_OFFSET_WIDTH = 5;
	localparam PPS_BETA_OFFSET_DIV2_WIDTH =  4;
	localparam PPS_TC_OFFSET_DIV2_WIDTH =  4;
	localparam STRONG_INTRA_SMOOTHING_WIDTH = 1;
	localparam CONSTRAINED_INTRA_PRED_WIDTH =  1;
	localparam NUM_SHORT_TERM_REF_WIDTH =  6;
	localparam WEIGHTED_PRED_WIDTH = 1;
	localparam WEIGHTED_BIPRED_WIDTH = 1;
	localparam PARALLEL_MERGE_LEVEL_WIDTH = 3;
	localparam RPS_HEADER_ID_WIDTH =  8;
	localparam NUM_POSITIVE_WIDTH = 8;
	localparam NUM_NEGATIVE_WIDTH = 8;
	localparam RPS_ID_WIDTH =  7;
	localparam RPS_ENTRY_USED_WIDTH = 1;
    localparam NUM_CURR_REF_POC_WIDTH = 4;
	localparam DELTA_POC_WIDTH = 16;
	localparam NULL_WIDTH = 24;
	localparam SHORT_TERM_REF_PIC_SPS_WIDTH =  1;
	localparam SHORT_TERM_REF_PIC_IDX_WIDTH =  4;
	localparam TEMPORAL_MVP_ENABLED_WIDTH =  1;
	localparam SAO_LUMA_WIDTH =  1;
	localparam SAO_CHROMA_WIDTH = 1;
	localparam NUM_REF_IDX_L0_MINUS1_WIDTH =  4;
	localparam NUM_REF_IDX_L1_MINUS1_WIDTH =  4;
	localparam MAX_MERGE_CAND_WIDTH =  3;
	localparam SLICE_TYPE_WIDTH =  2;
	localparam COLLOCATED_FROM_L0_FLAG_WIDTH =  1;
	localparam SLICE_CB_QP_OFFSET_WIDTH = 5;
	localparam SLICE_CR_QP_OFFSET_WIDTH = 5;
	localparam DISABLE_DBF_WIDTH =  1;
	localparam SLICE_BETA_OFFSET_DIV2_WIDTH =  4;
	localparam SLICE_TC_OFFSET_DIV2_WIDTH =  4;
	localparam COLLOCATED_REF_IDX_WIDTH =  5;
	localparam XC_WIDTH = 12;
	localparam YC_WIDTH = 12;
	localparam TILE_ID_WIDTH =  8;
	localparam SLICE_ID_WIDTH =  8;
	localparam SAOTYPE_WIDTH = 2;
	localparam BANDPOS_EO_WIDTH =  6;
	localparam BANDPOS_WIDTH =  5;
	localparam EOCLASS_WIDTH =  2;
	localparam SAO_OFFSET_ABS_0_WIDTH = 5 ;
	localparam SAO_OFFSET_SIGN_0_WIDTH = 1;
	localparam SAO_OFFSET_ABS_1_WIDTH = 5 ;
	localparam SAO_OFFSET_SIGN_1_WIDTH = 1;
	localparam SAO_OFFSET_ABS_2_WIDTH = 5 ;
	localparam SAO_OFFSET_SIGN_2_WIDTH = 1;
	localparam SAO_OFFSET_ABS_3_WIDTH = 5 ;
	localparam SAO_OFFSET_SIGN_3_WIDTH = 1;
	localparam SAO_OFFSET_WIDTH = 6;
	localparam	LOOP_FILTER_ACCROSS_TILES_FLAG_POSITION = 19;
	localparam	LOOP_FILTER_ACCROSS_SLICES_FLAG_POSITION = 30;
	localparam	PCM_LOOP_FILTER_DISABLED_FLAG_POSITION = 31;
	localparam X0_WIDTH = 6;
	localparam Y0_WIDTH = 6;
	localparam LOG2_CB_SIZE_WIDTH = 3;
	localparam PREDMODE_WIDTH =  1;
	localparam PARTMODE_WIDTH = 3;
	localparam BYPASS_WIDTH =  1;
	localparam PCM_WIDTH = 1;
    localparam PART_IDX_WIDTH =  2;
	localparam PRED_IDC_WIDTH = 2;
    localparam MERGE_FLAG_WIDTH = 1;
	localparam MERGE_IDX_WIDTH = 3;
	localparam MVP_L0_FLAG_WIDTH = 1;
	localparam MVP_L1_FLAG_WIDTH = 1;
	localparam REF_IDX_LX_WIDTH = 4;
    localparam MVD_WIDTH =16;
	localparam XT_WIDTH =  5;
	localparam YT_WIDTH =  5;
	localparam CIDX_WIDTH =  2;
	localparam INTRAMODE_WIDTH = 6;
	localparam RES_PRESENT_WIDTH = 1;
	localparam TRANSFORM_SKIP_FLAG_WIDTH =  1;
	localparam BSH_WIDTH = 2;
	localparam BSV_WIDTH = 2;
	localparam QP_WIDTH = 6;
    localparam BS_WIDTH 	= 2;
	localparam BS_H1_WIDTH = 2;
	localparam BS_H2_WIDTH = 2;
	localparam BS_V1_WIDTH = 2;
	localparam BS_V2_WIDTH = 2;
   localparam CHMA_FMT_IDC_WIDTH = 2;
	localparam PCM_FLAG_WIDTH = 1;
    localparam BY_PASS_FLAG_WIDTH = 1;
	localparam DU_SIZE_WIDTH = 3;
    localparam DBP_ADDRESS_OFFSET  = 32'd0;
   /// localparam COLLOCATED_MV_OFFSET  = 32'h
    parameter                          RPS_HEADER_ADDR_WIDTH = 6;
    parameter                          NUM_NEG_POS_POC_WIDTH = 4;
    parameter                          RPS_HEADER_DATA_WIDTH = NUM_NEG_POS_POC_WIDTH*3;
    parameter                          RPS_ENTRY_DATA_WIDTH = DELTA_POC_WIDTH + RPS_ENTRY_USED_WIDTH;
    parameter                          RPS_ENTRY_ADDR_WIDTH = RPS_HEADER_ADDR_WIDTH + NUM_NEG_POS_POC_WIDTH;   // maximum 65
    parameter RPS_HEADER_NUM_POS_POC_RANGE_HIGH        = RPS_HEADER_DATA_WIDTH - 1                                                                    ;
    parameter RPS_HEADER_NUM_POS_POC_RANGE_LOW         = RPS_HEADER_DATA_WIDTH - NUM_NEG_POS_POC_WIDTH                                                ;
    parameter RPS_HEADER_NUM_NEG_POC_RANGE_HIGH        = RPS_HEADER_DATA_WIDTH - NUM_NEG_POS_POC_WIDTH -1                                             ;
    parameter RPS_HEADER_NUM_NEG_POC_RANGE_LOW         = RPS_HEADER_DATA_WIDTH - NUM_NEG_POS_POC_WIDTH - NUM_NEG_POS_POC_WIDTH                        ;
    parameter RPS_HEADER_NUM_DELTA_POC_RANGE_HIGH      = RPS_HEADER_DATA_WIDTH - NUM_NEG_POS_POC_WIDTH - NUM_NEG_POS_POC_WIDTH -1                     ;
    parameter RPS_HEADER_NUM_DELTA_POC_RANGE_LOW       = RPS_HEADER_DATA_WIDTH - NUM_NEG_POS_POC_WIDTH - NUM_NEG_POS_POC_WIDTH - NUM_NEG_POS_POC_WIDTH;
    parameter RPS_ENTRY_USED_FLAG_RANGE_HIGH           = RPS_ENTRY_DATA_WIDTH - 1                                       ;
    parameter RPS_ENTRY_USED_FLAG_RANGE_LOW            = RPS_ENTRY_DATA_WIDTH - RPS_ENTRY_USED_WIDTH                    ;
    parameter RPS_ENTRY_DELTA_POC_RANGE_HIGH           = RPS_ENTRY_DATA_WIDTH - RPS_ENTRY_USED_WIDTH - 1                ;
    parameter RPS_ENTRY_DELTA_POC_RANGE_LOW            = RPS_ENTRY_DATA_WIDTH - RPS_ENTRY_USED_WIDTH - DELTA_POC_WIDTH  ;
    parameter RPS_ENTRY_DELTA_POC_MSB                  = RPS_ENTRY_DATA_WIDTH - RPS_ENTRY_USED_WIDTH - 1 ;
    parameter BS_FIFO_WIDTH = 8;
`ifdef HEVC_4K
    parameter X_ADDR_WDTH = 12;
    parameter X11_ADDR_WDTH = X_ADDR_WDTH;
    parameter Y_ADDR_WDTH = 12;
    parameter Y11_ADDR_WDTH = Y_ADDR_WDTH;
    localparam X_CAND_WDTH = X11_ADDR_WDTH+1;
    localparam Y_CAND_WDTH = Y11_ADDR_WDTH+1;
`else
    parameter X_ADDR_WDTH = 12;
    parameter X11_ADDR_WDTH = 11;
    parameter Y_ADDR_WDTH = 12;
    parameter Y11_ADDR_WDTH = 11;
    localparam X_CAND_WDTH = X11_ADDR_WDTH+1;
    localparam Y_CAND_WDTH = Y11_ADDR_WDTH+1;
`endif
	
    parameter LOG2_MIN_PU_SIZE = 2;
    parameter LOG2_MIN_TU_SIZE = 2;
    parameter LOG2_MIN_DU_SIZE = 3;
    `define AVAILABLE_CONFIG_IDLE           2'd0
    `define AVAILABLE_CONFIG_PIC_DIM        2'd1
    `define AVAILABLE_CONFIG_PIC_SLICE      2'd2
    `define AVAILABLE_CONFIG_PIC_TILE       2'd3
    parameter   AVAILABLE_CONFIG_BUS_WIDTH = 2;
    parameter                           POC_WIDTH = 32;
    parameter                           DPB_FRAME_OFFSET_WIDTH      = 4;
    parameter                           DPB_STATUS_WIDTH            = 3;
    parameter                           DPB_FILLED_WIDTH            = 1;
    parameter                           DPB_DATA_WIDTH              =   POC_WIDTH;
    parameter                           REF_PIC_LIST_POC_DATA_WIDTH =   POC_WIDTH;
    parameter                           DPB_REF_PIC_ADDR_WIDTH              =   28;
    parameter                           DPB_ADDR_WIDTH              =   DPB_FRAME_OFFSET_WIDTH;
    parameter                           REF_PIC_LIST_ADDR_WIDTH     =   DPB_FRAME_OFFSET_WIDTH;
    parameter                           REF_PIC_LIST_DATA_WIDTH     =   POC_WIDTH + DPB_FRAME_OFFSET_WIDTH;
    parameter                           REF_POC_LIST5_ADDR_WIDTH    =   DPB_FRAME_OFFSET_WIDTH;
    parameter                           REF_POC_LIST5_DATA_WIDTH    =   DELTA_POC_WIDTH + DPB_STATUS_WIDTH;
    `define INTER_TOP_CONFIG_IDLE           5'd0
    `define INTER_TOP_PARA_0                5'd1
    `define INTER_TOP_PARA_1                5'd2
    `define INTER_TOP_PARA_2                5'd3
    `define INTER_TOP_SLICE_1               5'd4
    `define INTER_TOP_SLICE_2               5'd5
    `define INTER_TOP_CURR_POC              5'd7
    `define INTER_CURRENT_PIC_DPB_IDX       5'd8
    `define INTER_SLICE_TILE_INFO           5'd9
    `define INTER_REF_PIC_TRANSFER          5'd10
    `define INTER_CU_HEADER                 5'd11
    `define INTER_PU_HEADER                 5'd12
    `define INTER_CTU0_HEADER               5'd13
    `define INTER_MVD_0_INFO                5'd14
    `define INTER_MVD_1_INFO                5'd15
    `define INTER_RU_0_HEADER               5'd16
    `define INTER_END_REF_PIC_TRANSFER      5'd17
    parameter                           INTER_TOP_CONFIG_BUS_MODE_WIDTH       = 5;
    parameter                           INTER_TOP_CONFIG_BUS_WIDTH            =32;
    parameter                           MV_FIELD_DATA_WIDTH = (1 + REF_IDX_LX_WIDTH + MVD_WIDTH + MVD_WIDTH)*2;
    parameter                   MV_COL_AXI_DATA_WIDTH = 512;
    parameter DPB_POC_RANGE_HIGH        = DPB_DATA_WIDTH - 1                                              ;
    parameter DPB_POC_RANGE_LOW         = DPB_DATA_WIDTH - POC_WIDTH                                      ;
    parameter REF_PIC_LIST5_POC_RANGE_HIGH  = REF_POC_LIST5_DATA_WIDTH - DPB_STATUS_WIDTH -1;
    parameter REF_PIC_LIST5_POC_RANGE_LOW   = REF_POC_LIST5_DATA_WIDTH - DPB_STATUS_WIDTH - DELTA_POC_WIDTH;
    parameter REF_PIC_LIST5_DPB_STATE_HIGH  = REF_POC_LIST5_DATA_WIDTH - 1;
    parameter REF_PIC_LIST5_DPB_STATE_LOW   = REF_POC_LIST5_DATA_WIDTH - DPB_STATUS_WIDTH ;
    `define MV_MERGE_CAND_NONE  3'd0
    `define MV_MERGE_CAND_A0    3'd1
    `define MV_MERGE_CAND_A1    3'd2
    `define MV_MERGE_CAND_B0    3'd3
    `define MV_MERGE_CAND_B1    3'd4
    `define MV_MERGE_CAND_B2    3'd5
    `define MV_MERGE_CAND_COL   3'd6
    `define MV_MERGE_CAND_BI    3'd7
    `define MV_MERGE_CAND_ZERO  3'd0
    `define MV_AMVP_CAND_A   3'd1
    `define MV_AMVP_CAND_B   3'd2
    `define MV_AMVP_CAND_COL   3'd3
    `define MV_AMVP_CAND_ZERO   3'd0
    parameter MERGE_CAND_TYPE_WIDTH = 3;
    parameter MAX_NUM_MERGE_CAND_CONST = 5;
    parameter AMVP_NUM_CAND_CONST = 2;
    parameter   NUM_BI_PRED_CANDS = 12;
    parameter   TX_WIDTH = 16;
    parameter   DIST_SCALE_WIDTH = 13;
    `define MVP_FILLE_MV_NO 2'd0
    `define MVP_FILLE_MV_A0 2'd1
    `define MVP_FILLE_MV_A1 2'd2
    `define MVP_FILLE_MV_B0 2'd1
    `define MVP_FILLE_MV_B1 2'd2
    `define MVP_FILLE_MV_B2 2'd3
    parameter NUM_BI_PRED_CANDS_TYPES = 4;
    localparam  MAX_LOG2CTBSIZE_WIDTH       = 3;
	
    parameter  LOG2_FRAME_SIZE             = X11_ADDR_WDTH+1;
    parameter  PIXEL_ADDR_LENGTH           = X11_ADDR_WDTH+1;
    localparam  INTRA_MODE_WIDTH            = 6;
    parameter  NTBS_SH_WDTH = 2;
`ifdef DEF_CH_TYPE_444
        localparam  MAX_NTBS_SIZE               = 7;
`else
        localparam  MAX_NTBS_SIZE               = 6;
`endif
    
    localparam  CONFIG_DATA_BUS_WIDTH       = 32;
    
    //`define KAS_VERIFY   
    //`define PRINT_PRED_RESI_FIN
    //`define LUMA_PRED_PRINT
    //`define CHROMA_CB_PRED_PRINT
    //`define CHROMA_CR_PRED_PRINT
    //`define KAS_TESTING   
    `define CH_FORMAT_420 8'h20
    `define CH_FORMAT_422 8'h22
    `define CH_FORMAT_444 8'h44
   
   `ifdef DEF_CH_TYPE_444
       parameter                          C_SUB_WIDTH  = 1;
       parameter                          C_SUB_HEIGHT = 1;
       parameter                          CH_FORMAT_IDC = `CH_FORMAT_444;
       parameter                          CHROMA_ARRAY_TYPE = 3;
    `elsif DEF_CH_TYPE_422
       parameter                          C_SUB_WIDTH  = 2;
       parameter                          C_SUB_HEIGHT = 1;
       parameter                          CH_FORMAT_IDC = `CH_FORMAT_422;
       parameter                          CHROMA_ARRAY_TYPE = 2;
    `else     
       parameter                          C_SUB_WIDTH  = 2;
       parameter                          C_SUB_HEIGHT = 2;
       parameter                          CH_FORMAT_IDC = `CH_FORMAT_420;
       parameter                          CHROMA_ARRAY_TYPE = 1;
    `endif
    
    
   `ifdef BIT_DEPTH_8
         parameter  PIXEL_WIDTH                  = 8;
        
    `elsif BIT_DEPTH_10
         parameter  PIXEL_WIDTH                  = 10;
    `elsif BIT_DEPTH_12     
         parameter  PIXEL_WIDTH                  = 12;
    `else
        //parameter  PIXEL_WIDTH                 = 8;
        //localparam  BIT_DEPTH                   = PIXEL_WIDTH;
    `endif
   // localparam  LUMA_BITS = PIXEL_WIDTH;
   localparam  CHMA_BITS = PIXEL_WIDTH;
   localparam  BIT_DEPTH                   = PIXEL_WIDTH;
   localparam PIXEL_BITS = PIXEL_WIDTH + (2*PIXEL_WIDTH)/(C_SUB_WIDTH*C_SUB_HEIGHT); 
   
   localparam CL_AXI_DIV_FAC1 = ({3{(BIT_DEPTH==8)}} & 3'd1) | ({3{(BIT_DEPTH==10)}} & 3'd2) | ({3{(BIT_DEPTH==12)}} & 3'd2); 
   localparam CL_AXI_DIV_FAC  = ({3{(BIT_DEPTH==8)}} & 3'd1) | ({3{(BIT_DEPTH==10)}} & 3'd2) | ({3{(BIT_DEPTH==12)}} & 3'd2); 
     
   /*
   PIXEL_BITS/CACHE_LINE_WIDTH(AXI LEN)
                     8              10             12
                     
      420           12/768(2)       15/960(2)      18/1152(3)
      422           16/1024(2)      20/1280(3)    24/1536(3)      
      444           24/1536(3)
   
   
   */
   /*
   BIT_DEPTH/CACHE_LINE_WIDTH(AXI LEN)
                     8              10             12
                     
      420           512(1)          640(2)         768(2)

   
   
   */
    parameter  MAX_RESI_READ_DEPTH          = (16 * 32);
    
    // `ifdef BIT_DEPTH_8
        // parameter RESIDUAL_STRUCT_SIZE = 24;
    // `elsif BIT_DEPTH_10
        // parameter RESIDUAL_STRUCT_SIZE = 32;
    // `elsif BIT_DEPTH_12     
        // parameter RESIDUAL_STRUCT_SIZE = 32;
    // `else
        // parameter RESIDUAL_STRUCT_SIZE = 24;
    // `endif
        
    parameter  OUTPUT_BLOCK_SIZE                = 4;
    parameter  RESIDUAL_WIDTH 		            = PIXEL_WIDTH + 1;
    parameter  DBF_YY_BLOCK_SIZE                = 4;
    parameter  DBF_CH_BLOCK_HIGHT               = 4/C_SUB_HEIGHT;
    parameter  DBF_CH_BLOCK_WIDTH               = 4/C_SUB_WIDTH;
    parameter  DBF_OUT_CH_BLOCK_HIGHT           = 8/C_SUB_HEIGHT;
    parameter  DBF_OUT_CH_BLOCK_WIDTH           = 8/C_SUB_WIDTH;
    parameter  DBF_OUT_Y_BLOCK_SIZE             = 8;
    parameter  SAO_OUT_FIFO_WIDTH               = PIXEL_WIDTH * DBF_OUT_Y_BLOCK_SIZE * DBF_OUT_Y_BLOCK_SIZE + PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH * 2  + (X_ADDR_WDTH - LOG2_MIN_DU_SIZE) * 2;  
    parameter  SAO_OUT_FIFO_WIDTH_XYL           = PIXEL_WIDTH * DBF_OUT_Y_BLOCK_SIZE * DBF_OUT_Y_BLOCK_SIZE                                                                      + (X_ADDR_WDTH - LOG2_MIN_DU_SIZE) * 2;
    parameter  SAO_OUT_FIFO_WIDTH_CH            =                                                             PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH * 2                                        ;
    parameter  SAO_OUT_FIFO_WIDTH_CB            =                                                             PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH                                            ;
    parameter  SAO_OUT_FIFO_WIDTH_CR            =                                                             PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH                                            ;
    
    parameter  SAO_OUT_FIFO_WIDTH_XYL_CB_HALF   = PIXEL_WIDTH * DBF_OUT_Y_BLOCK_SIZE * DBF_OUT_Y_BLOCK_SIZE + (X_ADDR_WDTH - LOG2_MIN_DU_SIZE) * 2 + PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH / 2;
    parameter  SAO_OUT_FIFO_WIDTH_CB_HALF_CR    = PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH / 2 + PIXEL_WIDTH * DBF_OUT_CH_BLOCK_HIGHT * DBF_OUT_CH_BLOCK_WIDTH;
    
    parameter DISPLAY_BUFFER_AXI_DATA_WIDTH     = 128;
    
    //if this value is changed, then needed to change the display data out module as well.
    //MSB = 1 => start of a frame
    parameter HDMI_FIFO_OUT_WIDTH  = (DISPLAY_BUFFER_AXI_DATA_WIDTH + 1); 
    
    parameter  FILTER_PIXEL_WIDTH = 16;
    parameter  NUM_IN_TO_8_FILTER = 8;
    `define CH_TYPE_1 2'b01
    `define CH_TYPE_2 2'b10
    `define CH_TYPE_3 2'b11
    `define CH_TYPE_4 2'b00
    parameter                          MAX_MV_PER_CU = 4;
    parameter                          STEP_8x8_IN_PUS = 2;
    parameter                          MV_L_FRAC_WIDTH_HIGH = 2;
    parameter                          MV_L_INT_WIDTH_LOW = 2;
    parameter                          MV_C_FRAC_WIDTH_HIGH = 3;
    parameter                          MV_C_INT_WIDTH_LOW = 3;
    
    
    
//************CACHE CONFIG DEF**********************************//
   parameter C_LG_BANKS = 0;
   parameter NUM_BANKS = (1<<C_LG_BANKS);
   
//Global header
localparam C_SIZE  = 13;
localparam C_L_V_SIZE = 3;
localparam C_L_V_SIZE_C = C_L_V_SIZE-(C_SUB_HEIGHT-1);
localparam C_L_H_SIZE = 3;
localparam C_L_H_SIZE_C = C_L_H_SIZE -(C_SUB_WIDTH-1);
localparam C_N_WAY  = 3;
localparam ADDR_WDTH  = 28;
localparam TAG_ADDR_WDTH    = ADDR_WDTH - C_SIZE + C_N_WAY;
localparam OFFSET_ADDR_WDTH = C_L_H_SIZE + C_L_V_SIZE;
localparam SET_ADDR_WDTH = C_SIZE - C_N_WAY - OFFSET_ADDR_WDTH;
localparam SET_ADDR_X_WIDTH = SET_ADDR_WDTH>>1;
localparam SET_ADDR_Y_WIDTH = SET_ADDR_WDTH>>1;
localparam CACHE_LINE_WDTH = 1 << (C_L_H_SIZE + C_L_V_SIZE);
localparam SET_INDEX_WDTH = C_N_WAY;
//localparam Y_BANK_BITS			    = 2;
localparam REF_ADDR_WDTH = 4;
//`define vertex5
//`define simulate
//`define mem_bypass
