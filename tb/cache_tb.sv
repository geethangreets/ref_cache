`timescale 1ns/1ps
module cache_tb();


    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"
    `include "../sim/cache_configs_def.v"    
    
    parameter IBC_REF_BLK_WIDTH = 8;
    parameter X_FILE_WIDTH = 32;
	parameter YY_WIDTH = PIXEL_WIDTH*DBF_OUT_Y_BLOCK_SIZE*DBF_OUT_Y_BLOCK_SIZE;
    
    const realtime CLOCK_PERIOD = 10;
    const realtime HALF_CLOCK_PERIOD = CLOCK_PERIOD / 2;
    const realtime APP_TIME  = 0 * CLOCK_PERIOD;
    //   const realtime RESP_TIME = 0.8 * CLOCK_PERIOD;


    // signal declaration
    logic  clk = 0;
    logic  reset ;
    
//////////////////WIRE declaration ////////////////////////
    logic                                         valid_in; 
    logic								          cache_valid_out;   // assuming cache_block_ready is single cylce 
    logic										  cache_idle_out;
    logic                                         filer_idle_in;
    logic                                         cache_full_idle;

	logic signed [32 -1:0] 	cur_x_idx;	
	logic signed [32 -1:0] 	cur_y_idx;
    wire [YY_WIDTH-1:0] yy_pixels_8x8;
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_x_in;	
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_y_in;
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_x_in;	
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	chma_ref_start_y_in;	
	
	logic  [LUMA_DIM_WDTH - 1:0]   			                chma_ref_width_x_in            ;	
    logic  [LUMA_DIM_WDTH - 1:0]                            chma_ref_height_y_in           ;   
	logic  [LUMA_DIM_WDTH - 1:0]   			                luma_ref_width_x_in            ;	
    logic  [LUMA_DIM_WDTH - 1:0]                            luma_ref_height_y_in           ;  

    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]          luma_ref_start_x_out   ;
    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]          luma_ref_start_y_out   ;
    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]          chma_ref_start_x_out   ;
    logic  [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0]          chma_ref_start_y_out   ;
   
    logic   [LUMA_DIM_WDTH - 1:0]                           chma_ref_width_x_out   ;
    logic   [LUMA_DIM_WDTH - 1:0]                           chma_ref_height_y_out  ;
    logic   [LUMA_DIM_WDTH - 1:0]                           luma_ref_width_x_out   ;
    logic   [LUMA_DIM_WDTH - 1:0]                           luma_ref_height_y_out  ;


    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                     ch_frac_x;
    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                     ch_frac_y;
    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                     ch_frac_x_out;
    logic   [MV_C_FRAC_WIDTH_HIGH -1:0]                     ch_frac_y_out; 
   
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
    
    logic                               write_back_rd_en;
    logic                               write_back_empty;
    logic                               write_back_nempty;
    logic [(X_ADDR_WDTH -LOG2_MIN_DU_SIZE)*2 + (BIT_DEPTH * IBC_REF_BLK_WIDTH * IBC_REF_BLK_WIDTH) -1 :0]     write_back_data;

// axi master read interface  ------------------------------------------       
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
    
    
    logic                                                       ref_pix_axi_awid    ;
    logic  [7:0]                                                ref_pix_axi_awlen   ;
    logic  [2:0]                                                ref_pix_axi_awsize  ;
    logic  [1:0]                                                ref_pix_axi_awburst ;
    logic                    	                                ref_pix_axi_awlock  ;
    logic  [3:0]                                                ref_pix_axi_awcache ;
    logic  [2:0]                                                ref_pix_axi_awprot  ;
    logic                                                       ref_pix_axi_awvalid	;
    logic  [AXI_ADDR_WDTH-1:0]                                  ref_pix_axi_awaddr	;
    logic                    	                                ref_pix_axi_awready	;
    // write data channel
    logic      [AXI_CACHE_DATA_WDTH/8-1:0]	                    ref_pix_axi_wstrb	;
    logic                                 	                    ref_pix_axi_wlast	;
    logic                                 	                    ref_pix_axi_wvalid	;
    logic     [AXI_CACHE_DATA_WDTH -1:0]	                    ref_pix_axi_wdata	;
    logic                                                       ref_pix_axi_wready	;
    //write response channel
    logic                      	                                ref_pix_axi_bid		;
    logic      [1:0]                                            ref_pix_axi_bresp	;
    logic                      	                                ref_pix_axi_bvalid	;
    logic                                                       ref_pix_axi_bready	;      
    
    
// axi master write interface  ------------------------------------------  
    wire                                                        axi_awid    ;
    wire  [7:0]                                                 axi_awlen   ;
    wire  [2:0]                                                 axi_awsize  ;
    wire  [1:0]                                                 axi_awburst ;
    wire                    	                                axi_awlock  ;
    wire  [3:0]                                                 axi_awcache ;
    wire  [2:0]                                                 axi_awprot  ;
    wire                                                        axi_awvalid	;
    wire  [AXI_ADDR_WDTH-1:0]                                   axi_awaddr	;
    wire                  	                                    axi_awready	;
    wire  [AXI_CACHE_DATA_WDTH/8-1:0]	                        axi_wstrb	;
    wire                                 	                    axi_wlast	;
    wire                                 	                    axi_wvalid	;
    wire  [AXI_CACHE_DATA_WDTH -1:0]	                        axi_wdata	;
    wire                                                        axi_wready	;
    wire                     	                                axi_bid		;
    wire  [1:0]                                                 axi_bresp	;
    wire                     	                                axi_bvalid	;
    wire                                                        axi_bready	;
            
    logic [X_FILE_WIDTH*2-1:0]              file_rdata;
    
    initial begin
        reset =1;
        $timeformat(-9, 0, "ns", 6); // Format time output
        #((5 * CLOCK_PERIOD) + APP_TIME); // Wait some time until releasing reset
        // ddr_soft_mem_block.data_wr_rd_block.memory.add_ref_DPB(int base_addr, int poc, int height, int width, int bit_depth, int SubWidthC, int SubHeightC);
        //ddr_soft_mem_block.data_wr_rd_block.memory.add_ref_DPB   (            0,       0,       1080,      1920,             8,             2,              2);
        reset = 0;
        #((10 * CLOCK_PERIOD) + APP_TIME);

    end //initial
    always
        #HALF_CLOCK_PERIOD clk = ~clk;

wire read_req_bit_n ;
request_issuer
#(
    .BLOCK_SIZE     (IBC_REF_BLK_WIDTH),
    .IMG_WIDTH      (1920),
    .IMG_HEIGHT     (1080)
)
request_issuer
(
    .clk                 (clk)                  ,
    .reset               (reset)                ,
    .cache_idle_in       (cache_idle_out)       ,
    .cache_valid_out     (valid_in)             ,
	.cache_req_data_out  (file_rdata)           ,
    .write_back_en_out   (read_req_bit_n)         ,
	.write_back_ack_in   (cache_idle_out)     ,
	.write_back_data     (write_back_data)
);

assign  {cur_x_idx[X_ADDR_WDTH -1: LOG2_MIN_DU_SIZE],cur_y_idx[X_ADDR_WDTH -1: LOG2_MIN_DU_SIZE],yy_pixels_8x8} 
        = write_back_data;
assign cur_x_idx[32 -1:(X_ADDR_WDTH)] = 0;
assign cur_y_idx[32 -1:(X_ADDR_WDTH)] = 0;
assign cur_x_idx[LOG2_MIN_DU_SIZE-1:0] = 0;
assign cur_y_idx[LOG2_MIN_DU_SIZE-1:0] = 0;
assign {luma_ref_start_x_in} = read_req_bit_n ? cur_x_idx[MVD_WIDTH -  MV_L_FRAC_WIDTH_HIGH -1:0] :file_rdata[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0];
assign {luma_ref_start_y_in} = read_req_bit_n ? cur_y_idx[MVD_WIDTH -  MV_L_FRAC_WIDTH_HIGH -1:0] :file_rdata[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1+X_FILE_WIDTH:0+X_FILE_WIDTH];

assign write_back_empty = ~ write_back_nempty;

inter_cache_pipe_hit_pipe cache_top
(
    .clk                               (clk)  ,
    .reset                             (reset)  ,

//-------upstream interface------
	.ref_idx_in_in                     (0)          ,           // default to zero (for current frame)
    .valid_in                          ((valid_in|(read_req_bit_n & cache_idle_out) ))   ,           // upstream input valid
    .is_req_read                       (~read_req_bit_n)       ,           // read requests
    .wb_data_in                        (write_back_data )  ,         
    .cache_idle_out                    (cache_idle_out)  ,         // 1 - cache is ready to accept new input

    .pic_width                         (1920)  ,
    .pic_height                        (1080)  ,
    .ch_frac_x                         (0)  ,       //optional default to zero
    .ch_frac_y                         (0)  ,       //optional default to zero
    
    .luma_ref_start_x_in 	           (luma_ref_start_x_in)  ,   // start x location of luma pixel address
    .luma_ref_start_y_in               (luma_ref_start_y_in)  ,    // start y location of luma pixel address 
    .chma_ref_start_x_in 	           ('d0)  ,   // start x location of chroma 
    .chma_ref_start_y_in 	           ('d0)  ,   // start y location of chroma 
    .luma_ref_width_x_in               ('d7)  ,     //width of reference block in luma (zero based))
    .chma_ref_width_x_in               ('d0)  ,     //width of reference block in chroma (zero based))
    .luma_ref_height_y_in              ('d7)  ,     //height of reference block in luma (zero based))
    .chma_ref_height_y_in              ('d0)  ,     //height of reference block in chroma (zero based))

//-------downstream interface------
    .luma_ref_start_x_out              ()  ,  //block dimension output for reference 
    .luma_ref_start_y_out              ()  ,   //block dimension output for reference 
    .chma_ref_start_x_out              ()  ,  //block dimension output for reference
    .chma_ref_start_y_out              ()  ,  //block dimension output for reference
    .luma_ref_width_x_out              ()  ,    //block dimension output for reference 
    .chma_ref_width_x_out              ()  ,    //block dimension output for reference 
    .luma_ref_height_y_out             ()  ,    //block dimension output for reference 
    .chma_ref_height_y_out             ()  ,    //block dimension output for reference 
    
	
    .block_x_offset_luma               ()  ,   // valid pixel starting location x direction in luma output - block width if target within picture boundaries
    .block_y_offset_luma               ()  ,   // valid pixel starting location y direction in luma output - block width if target within picture boundaries
    .block_x_offset_chma               ()  ,   // valid pixel starting location x direction in chroma output - block width if target within picture boundaries
    .block_y_offset_chma               ()  ,   // valid pixel starting location y direction in chroma output - block width if target within picture boundaries
    .block_x_end_luma                  ()  ,   // valid pixel ending location x direction in luma output - zero if target within picture boundaries
    .block_y_end_luma                  ()  ,   // valid pixel ending location y direction in luma output - zero if target within picture boundaries
    .block_x_end_chma                  ()  ,   // valid pixel ending location x direction in chroma output - zero if target within picture boundaries
    .block_y_end_chma                  ()  ,   // valid pixel ending location y direction in chroma output - zero if target within picture boundaries

    .ch_frac_x_out                     ()  ,      //optional 
    .ch_frac_y_out                     ()  ,      //optional

    .filer_idle_in                     (1'b1)  ,      // 1 means down stream module is ready to accept new data
    .luma_ref_block_out                (luma_ref_block_out)  , // y reference block
    .cb_ref_block_out                  ()  ,   // cb reference block
    .cr_ref_block_out                  ()  ,   // cr reference block
    .cache_valid_out                   (cache_valid_out)  ,    //1 - valid output
    
//--- auxilary status---------------
	.cache_full_idle                   (cache_full_idle     ),// asserts when all blocks in cache is fully idle
    
//----axi interface-----------------
    
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
    .ref_pix_axi_r_ready               (ref_pix_axi_r_ready )  

    ,.ref_pix_axi_awid                  (ref_pix_axi_awid     )      //TODO
    ,.ref_pix_axi_awlen                 (ref_pix_axi_awlen    )
    ,.ref_pix_axi_awsize                (ref_pix_axi_awsize   )
    ,.ref_pix_axi_awburst               (ref_pix_axi_awburst  )
    ,.ref_pix_axi_awlock                (ref_pix_axi_awlock   )
    ,.ref_pix_axi_awcache               (ref_pix_axi_awcache  )
    ,.ref_pix_axi_awprot                (ref_pix_axi_awprot   )
    ,.ref_pix_axi_awvalid               (ref_pix_axi_awvalid  )
    ,.ref_pix_axi_awaddr                (ref_pix_axi_awaddr   )
    ,.ref_pix_axi_awready               (ref_pix_axi_awready  )
    ,.ref_pix_axi_wstrb	                (ref_pix_axi_wstrb    )
    ,.ref_pix_axi_wlast                 (ref_pix_axi_wlast    )
    ,.ref_pix_axi_wvalid                (ref_pix_axi_wvalid   )
    ,.ref_pix_axi_wdata                 (ref_pix_axi_wdata    )
    ,.ref_pix_axi_wready                (ref_pix_axi_wready   )
    ,.ref_pix_axi_bid                   (ref_pix_axi_bid      )
    ,.ref_pix_axi_bresp	                (ref_pix_axi_bresp	 )
    ,.ref_pix_axi_bvalid	            (ref_pix_axi_bvalid	 )
    ,.ref_pix_axi_bready	            (ref_pix_axi_bready	 )

);


// ref_buf_to_axi_write_master
// cache_wb_blk
// (
    // .clk                 (clk  )       ,
    // .reset               (reset)       ,
	////fifo interface      
	// .fifo_is_empty_in    (write_back_empty  )       ,
	// .fifo_rd_en_out	     (write_back_rd_en	)       ,
	// .fifo_data_in	     (write_back_data   )       ,   
	// .dpb_axi_addr_in     (0   )       ,
    // .pic_width_in        (1920      )       ,
    // .pic_height_in       (1080     )       ,
    ////axi interface
    // .axi_awid            (axi_awid          )       ,     
    // .axi_awlen           (axi_awlen         )       ,    
    // .axi_awsize          (axi_awsize        )       ,   
    // .axi_awburst         (axi_awburst       )       ,  
    // .axi_awlock          (axi_awlock        )       ,   
    // .axi_awcache         (axi_awcache       )       ,  
    // .axi_awprot          (axi_awprot        )       ,   
    // .axi_awvalid         (axi_awvalid       )       ,
    // .axi_awaddr          (axi_awaddr        )       ,
    // .axi_awready         (axi_awready       )       ,
    // .axi_wstrb           (axi_wstrb         )       ,
    // .axi_wlast           (axi_wlast         )       ,
    // .axi_wvalid          (axi_wvalid        )       ,
    // .axi_wdata           (axi_wdata         )       ,
    // .axi_wready          (axi_wready        )       ,
    // .axi_bid             (axi_bid           )       ,
    // .axi_bresp           (axi_bresp         )       ,
    // .axi_bvalid          (axi_bvalid        )       ,
    // .axi_bready          (axi_bready        )
    
// );

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
        .araddr (ref_pix_axi_ar_addr        ),
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

        .awid       (ref_pix_axi_awid       ),
        .awaddr     (ref_pix_axi_awaddr     ),
        .awlen      (ref_pix_axi_awlen      ),
        .awsize     (ref_pix_axi_awsize     ),
        .awburst    (ref_pix_axi_awburst    ),
        .awlock     (ref_pix_axi_awlock     ),
        .awcache    (ref_pix_axi_awcache    ),
        .awprot     (ref_pix_axi_awprot     ),
        .awvalid    (ref_pix_axi_awvalid    ),
        .awready    (ref_pix_axi_awready    ),

        .wid        (   ),
        .wdata      (ref_pix_axi_wdata      ),
        .wstrb      (ref_pix_axi_wstrb      ),
        .wvalid     (ref_pix_axi_wvalid     ),
        .wlast      (ref_pix_axi_wlast      ),
        .wready     (ref_pix_axi_wready     ),
    
        .bid        (ref_pix_axi_bid        ),
        .bresp      (ref_pix_axi_bresp      ),
        .bvalid     (ref_pix_axi_bvalid     ),
        .bready     (ref_pix_axi_bready     )
     );

   

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



