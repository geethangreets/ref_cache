`timescale 1ns/1ps
module cache_tb();


    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"
    `include "../sim/cache_configs_def.v"    
    
    parameter IBC_REF_BLK_WIDTH = 8;
    
    const realtime CLOCK_PERIOD = 10;
    const realtime HALF_CLOCK_PERIOD = CLOCK_PERIOD / 2;
    const realtime APP_TIME  = 0 * CLOCK_PERIOD;
    //   const realtime RESP_TIME = 0.8 * CLOCK_PERIOD;


    // signal declaration
    logic  clk = 0;
    logic  reset ;
    
//////////////////WIRE declaration ////////////////////////
    logic                                         valid_in; 
    logic								         cache_valid_out;   // assuming cache_block_ready is single cylce 
    logic										 cache_idle_out;
    logic                                         filer_idle_in;
    logic                                         cache_full_idle;

	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_x_in;	
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_y_in;
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_x_in;	
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_y_in;	
	
	logic  [LUMA_DIM_WDTH - 1:0]   			               chma_ref_width_x_in            ;	
    logic  [LUMA_DIM_WDTH - 1:0]                           chma_ref_height_y_in           ;   
	logic  [LUMA_DIM_WDTH - 1:0]   			               luma_ref_width_x_in            ;	
    logic  [LUMA_DIM_WDTH - 1:0]                           luma_ref_height_y_in           ;  

    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]       luma_ref_start_x_out   ;
    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]       luma_ref_start_y_out   ;
    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]       chma_ref_start_x_out   ;
    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]       chma_ref_start_y_out   ;
   
    logic   [LUMA_DIM_WDTH - 1:0]                        chma_ref_width_x_out   ;
    logic   [LUMA_DIM_WDTH - 1:0]                        chma_ref_height_y_out  ;
    logic   [LUMA_DIM_WDTH - 1:0]                        luma_ref_width_x_out   ;
    logic   [LUMA_DIM_WDTH - 1:0]                        luma_ref_height_y_out  ;


    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_x;
    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_y;
    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_x_out;
    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                  ch_frac_y_out; 
   
    logic			[REF_ADDR_WDTH-1:0]		            ref_idx_in_in;
	
    logic [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]       pic_width;   
    logic [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]       pic_height;   
	
		
    logic         [LUMA_DIM_WDTH-1:0]                 block_x_offset_luma;
    logic         [LUMA_DIM_WDTH-1:0]                 block_y_offset_luma;
    logic         [CHMA_DIM_WDTH-1:0]                 block_x_offset_chma;
    logic         [CHMA_DIM_HIGT-1:0]                 block_y_offset_chma; 

    logic         [LUMA_DIM_WDTH-1:0]                 block_x_end_luma;
    logic         [LUMA_DIM_WDTH-1:0]                 block_y_end_luma;
    logic         [CHMA_DIM_WDTH-1:0]                 block_x_end_chma;
    logic         [CHMA_DIM_HIGT-1:0]                 block_y_end_chma; 
   
   
// datapath outputs	  ------------------------------------------       
    logic [BIT_DEPTH* IBC_REF_BLK_WIDTH* IBC_REF_BLK_WIDTH  -1:0]          block_8x8_unrolled;
    logic [BIT_DEPTH* LUMA_REF_BLOCK_WIDTH* LUMA_REF_BLOCK_WIDTH -1:0]     luma_ref_block_out;
    logic [BIT_DEPTH* CHMA_REF_BLOCK_WIDTH* CHMA_REF_BLOCK_HIGHT -1:0]     cb_ref_block_out;
    logic [BIT_DEPTH* CHMA_REF_BLOCK_WIDTH* CHMA_REF_BLOCK_HIGHT -1:0]     cr_ref_block_out;

// axi master interface  ------------------------------------------       
    logic [AXI_ADDR_WDTH-1:0]		                           ref_pix_axi_ar_addr;
    logic  [7:0]					                           ref_pix_axi_ar_len;
    logic 	[2:0]					                           ref_pix_axi_ar_size;
    logic  [1:0]					                           ref_pix_axi_ar_burst;
    logic  [2:0]					                           ref_pix_axi_ar_prot;
    logic 					            	                   ref_pix_axi_ar_valid;
    logic 						                               ref_pix_axi_ar_ready;
    logic [AXI_CACHE_DATA_WDTH-1:0]		                       ref_pix_axi_r_data;
    logic [1:0]					                               ref_pix_axi_r_resp;
    logic 						                               ref_pix_axi_r_last;
    logic 						                               ref_pix_axi_r_valid;
    logic 							                           ref_pix_axi_r_ready;
            
    logic [32-1:0]                                                     file_rdata;
    
    initial begin
        reset =1;
        $timeformat(-9, 0, "ns", 6); // Format time output
        #((5 * CLOCK_PERIOD) + APP_TIME); // Wait some time until releasing reset
        // ddr_soft_mem_block.data_wr_rd_block.memory.add_ref_DPB(int base_addr, int poc, int height, int width, int bit_depth, int SubWidthC, int SubHeightC);
        ddr_soft_mem_block.data_wr_rd_block.memory.add_ref_DPB   (            0,       0,       1080,      1920,             8,             2,              2);
        reset = 0;
        #((10 * CLOCK_PERIOD) + APP_TIME);

    end //initial
    always
        #HALF_CLOCK_PERIOD clk = ~clk;



inter_cache_pipe_hit_pipe cache_top
(
    .clk                               (clk)  ,
    .reset                             (reset)  ,

	.ref_idx_in_in                     (0)  ,      // default to zero (for current frame)
    .valid_in                          (valid_in)  ,           // input valid
    .cache_idle_out                    (cache_idle_out)  ,         // 1 - cache is ready to accept new input
    
    .luma_ref_start_x_in 	           (luma_ref_start_x_in)  ,   // start x location of luma 
    .luma_ref_start_y_in               (luma_ref_start_y_in)  ,    // start y location of luma 
    .chma_ref_start_x_in 	           (0)  ,   // start x location of chroma 
    .chma_ref_start_y_in 	           (0)  ,   // start y location of chroma 
    .luma_ref_width_x_in               (7)  ,     //width of reference block in luma (zero based))
    .chma_ref_width_x_in               (0)  ,     //width of reference block in chroma (zero based))
    .luma_ref_height_y_in              (7)  ,     //height of reference block in luma (zero based))
    .chma_ref_height_y_in              (0)  ,     //height of reference block in chroma (zero based))

    .luma_ref_start_x_out              ()  ,  //block dimension output for reference
    .luma_ref_start_y_out              ()  ,   //block dimension output for reference
    .chma_ref_start_x_out              ()  ,  //block dimension output for reference
    .chma_ref_start_y_out              ()  ,  //block dimension output for reference
    .luma_ref_width_x_out              ()  ,    //block dimension output for reference
    .chma_ref_width_x_out              ()  ,    //block dimension output for reference
    .luma_ref_height_y_out             ()  ,    //block dimension output for reference
    .chma_ref_height_y_out             ()  ,    //block dimension output for reference
    
	
    .block_x_offset_luma               ()  ,   // valid pixel starting location x direction in luma output
    .block_y_offset_luma               ()  ,   // valid pixel starting location y direction in luma output
    .block_x_offset_chma               ()  ,   // valid pixel starting location x direction in chroma output
    .block_y_offset_chma               ()  ,   // valid pixel starting location y direction in chroma output
    .block_x_end_luma                  ()  ,   // valid pixel ending location x direction in luma output
    .block_y_end_luma                  ()  ,   // valid pixel ending location y direction in luma output
    .block_x_end_chma                  ()  ,   // valid pixel ending location x direction in chroma output
    .block_y_end_chma                  ()  ,   // valid pixel ending location y direction in chroma output


    .pic_width                         (1920)  ,
    .pic_height                        (1080)  ,
    .ch_frac_x                         (0)  ,       //optional default to zero
    .ch_frac_y                         (0)  ,       //optional default to zero
    .ch_frac_x_out                     ()  ,      //optional 
    .ch_frac_y_out                     ()  ,      //optional

    .filer_idle_in                     (1'b1)  ,      // 1 means down stream module is ready to accept new data
    .luma_ref_block_out                (luma_ref_block_out)  , // y reference block
    .cb_ref_block_out                  ()  ,   // cb reference block
    .cr_ref_block_out                  ()  ,   // cr reference block
    .cache_valid_out                   (cache_valid_out)  ,    //1 - valid output
    
    .ref_pix_axi_ar_addr               (ref_pix_axi_ar_addr )  ,
    .ref_pix_axi_ar_len                (ref_pix_axi_ar_len  )  ,
    .ref_pix_axi_ar_size               (ref_pix_axi_ar_size )  ,
    .ref_pix_axi_ar_burst              (ref_pix_axi_ar_burst)  ,
    .ref_pix_axi_ar_prot               (ref_pix_axi_ar_prot )  ,
    .ref_pix_axi_ar_valid              (ref_pix_axi_ar_valid)  ,
    .ref_pix_axi_ar_ready              (ref_pix_axi_ar_ready)  ,
    .ref_pix_axi_r_data                (ref_pix_axi_r_data  )  ,
    .ref_pix_axi_r_resp                (ref_pix_axi_r_resp  )  ,
    .ref_pix_axi_r_last                (ref_pix_axi_r_last  )  ,
    .ref_pix_axi_r_valid               (ref_pix_axi_r_valid )  ,
    .ref_pix_axi_r_ready               (ref_pix_axi_r_ready )  ,
	.cache_full_idle                   (cache_full_idle     )// asserts when all blocks in cache is fully idle


);


// synthesis translate_off
    mem_slave_top_module
    #(
      .DUMMY_MEM(0),
      .READ_DATA_DEBUG(0),
      .WRITE_DATA_DEBUG(0)
    )
    ddr_soft_mem_block
    (   .clk    (clk),
        .reset  (reset),

        .arid   (4'd0),
        .araddr (ref_pix_axi_ar_addr),
        .arlen  (ref_pix_axi_ar_len),
        .arsize  (ref_pix_axi_ar_size),
        .arburst(ref_pix_axi_ar_burst),
        .arlock (0),
        .arcache(0),
        .arprot (ref_pix_axi_ar_prot),
        .arvalid(ref_pix_axi_ar_valid),
        .arready(ref_pix_axi_ar_ready),

        .rid    (),
        .rdata  (ref_pix_axi_r_data),
        .rresp  (ref_pix_axi_r_resp),
        .rlast  (ref_pix_axi_r_last),
        .rvalid (ref_pix_axi_r_valid),
        .rready (ref_pix_axi_r_ready),

        .awid   (   ),
        .awaddr (   ),
        .awlen  (   ),
        .awsize (   ),
        .awburst(   ),
        .awlock (),
        .awcache(),
        .awprot (),
        .awvalid( 1'b0  ),
        .awready(   ),

        .wid    (   ),
        .wdata  (   ),
        .wstrb  (   ),
        .wvalid ( 1'b0  ),
        .wlast  (   ),
        .wready (   ),

        .bid    (),
        .bresp  (),
        .bvalid (),
        .bready  (1'b1)
     );

assign {luma_ref_start_x_in} = file_rdata[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0];
assign {luma_ref_start_y_in} = file_rdata[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1+16:0+16];

//////////// INTERFACE DRIVERS /////////////////

fifo_write_driver 
#(
    .WIDTH (32),
    .RESET_TIME (100),
    .VALID_FIRST(1),
    .FILE_NAME("../simvectors/ibc_cache_request.bin")
)

xy_request_driver(
    .clk         (clk)                     ,
    .reset       (reset)                  ,
    .out         (file_rdata)     ,
    .ready       (cache_idle_out)       ,
    .address     (),
    .wr_en       (valid_in)        
);


//-----------------------------------------------------------------


    generate
        genvar ii;
        genvar jj;
        
        for(jj=0;jj <IBC_REF_BLK_WIDTH ; jj=jj+1 ) begin : row_iteration
            for(ii=0 ; ii < IBC_REF_BLK_WIDTH ; ii = ii+1) begin : column_iteration
                    assign  block_8x8_unrolled[(jj*IBC_REF_BLK_WIDTH + ii +1)*(BIT_DEPTH)-1: (jj*IBC_REF_BLK_WIDTH + ii)*BIT_DEPTH ] 
                            = luma_ref_block_out[(jj*LUMA_REF_BLOCK_WIDTH + ii +1)*(BIT_DEPTH)-1: (jj*LUMA_REF_BLOCK_WIDTH + ii)*BIT_DEPTH ] ;
            end
        end

    endgenerate 

//////////// INTERFACE MONITORS /////////////////

`ifdef INSERT_MONITORS

inf_monitor #( .WIDTH (BIT_DEPTH* IBC_REF_BLK_WIDTH* IBC_REF_BLK_WIDTH),.DEBUG (0) , .SKIP_ZERO (1), .FILE_NAME("../simvectors/ibc_cache_receive.bin"))
cache_out_mon( .clk (clk),.reset(reset),.data1(block_8x8_unrolled),.valid   (cache_valid_out) ,.ready(1'b1));


`endif


endmodule // cache_tb



