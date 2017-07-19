`timescale 1ns / 1ps

module ref_buf_to_axi_write_master(
    clk,
    reset,

	//fifo interface
	fifo_is_empty_in,
	fifo_rd_en_out	,
	fifo_data_in	,   	
	
	dpb_axi_addr_in,
	
    pic_width_in,
    pic_height_in,

	
    axi_awid        ,     
    axi_awlen       ,    
    axi_awsize      ,   
    axi_awburst     ,  
    axi_awlock      ,   
    axi_awcache     ,  
    axi_awprot      ,   
    axi_awvalid     ,
    axi_awaddr      ,
    axi_awready     ,
    axi_wstrb       ,
    axi_wlast       ,
    axi_wvalid      ,
    axi_wdata       ,
    axi_wready      ,
    axi_bid         ,
    axi_bresp       ,
    axi_bvalid      ,
    axi_bready       
    
    
);
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
`include "../sim/pred_def.v"
`include "../sim/inter_axi_def.v"
`include "../sim/cache_configs_def.v"
//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
    parameter                   PIX_REF_AXI_AX_SIZE  = `AX_SIZE_64;
    parameter                   PIX_REF_AXI_AX_LEN   = (CACHE_LINE_WDTH*PIXEL_BITS-1)/AXI_CACHE_DATA_WDTH;
	
	parameter YY_WIDTH = PIXEL_WIDTH*DBF_OUT_Y_BLOCK_SIZE*DBF_OUT_Y_BLOCK_SIZE;
	parameter CH_WIDTH = PIXEL_WIDTH*DBF_OUT_CH_BLOCK_HIGHT*DBF_OUT_CH_BLOCK_WIDTH;
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------
    localparam  STATE_AXI_WRITE_ADDRESS_SEND = 1;
    localparam  STATE_AXI_WRITE_ADDRESS_SEND_WAIT = 2;
    localparam  STATE_AXI_WRITE_WAIT = 3;
    localparam  STATE_AXI_WRITE_RESP = 4;
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input clk;
    input reset;
    //luma sao fifo interface
	input 							fifo_is_empty_in	;
	output reg 						fifo_rd_en_out		;
	input [SAO_OUT_FIFO_WIDTH-1:0]	fifo_data_in		;
	
	input [AXI_ADDR_WDTH -1:0]			dpb_axi_addr_in;
	
    input     [PIC_WIDTH_WIDTH-1:0]    pic_width_in;
    input     [PIC_WIDTH_WIDTH-1:0]    pic_height_in;

	
    output                                      axi_awid    ;
    output      [7:0]                           axi_awlen   ;
    output      [2:0]                           axi_awsize  ;
    output      [1:0]                           axi_awburst ;
    output                        	            axi_awlock  ;
    output      [3:0]                           axi_awcache ;
    output      [2:0]                           axi_awprot  ;
(* MARK_DEBUG *)    output reg                                  axi_awvalid	;
    (* dont_touch = "true" *) output reg  [AXI_ADDR_WDTH-1:0]             axi_awaddr	;
(* MARK_DEBUG *)    input                       	            axi_awready	;

    // write data channel
(* MARK_DEBUG *)    output reg      [AXI_CACHE_DATA_WDTH/8-1:0]	axi_wstrb	;
                    wire            [AXI_CACHE_DATA_WDTH/8-1:0]	axi_wstrb_nxt	;
(* MARK_DEBUG *)    output reg                                 	axi_wlast	;
(* MARK_DEBUG *)    output reg                                 	axi_wvalid	;
    output reg     [AXI_CACHE_DATA_WDTH -1:0]	axi_wdata	;

(* MARK_DEBUG *)    input	                                    axi_wready	;

    //write response channel
    input                       	            axi_bid		;
(* MARK_DEBUG *)    input       [1:0]                           axi_bresp	;
(* MARK_DEBUG *)    input                       	            axi_bvalid	;
(* MARK_DEBUG *)    output                                   axi_bready	;  
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

    
(* MARK_DEBUG *)    reg [31:0]                         state_axi_write;
    reg [7:0] burst_counter;
    
	wire [X_ADDR_WDTH -LOG2_MIN_DU_SIZE -1: 0]				Xc_out_8x8;
	wire [X_ADDR_WDTH -LOG2_MIN_DU_SIZE -1: 0]				Yc_out_8x8;	
	
	wire [PIXEL_WIDTH*DBF_OUT_Y_BLOCK_SIZE*DBF_OUT_Y_BLOCK_SIZE -1:0] 	yy_pixels_8x8;
	wire [PIXEL_WIDTH*DBF_OUT_CH_BLOCK_HIGHT*DBF_OUT_CH_BLOCK_WIDTH -1:0] cb_pixels_8x8;
	wire [PIXEL_WIDTH*DBF_OUT_CH_BLOCK_HIGHT*DBF_OUT_CH_BLOCK_WIDTH -1:0] cr_pixels_8x8;
	
	reg [AXI_ADDR_WDTH -1:0]			current_pic_dpb_base_addr_d;
	reg [AXI_ADDR_WDTH -1:0]			current_pic_dpb_base_addr_use;
  
    wire        [CTB_SIZE_WIDTH - LOG2_MIN_DU_SIZE - 1:0]      		y_8x8_in_ctu;
    wire        [CTB_SIZE_WIDTH - LOG2_MIN_DU_SIZE - 1:0]         	x_8x8_in_ctu;
    wire        [X11_ADDR_WDTH - CTB_SIZE_WIDTH - 1:0]          	   x_ctu;
    wire        [X11_ADDR_WDTH - CTB_SIZE_WIDTH - 1:0]         		y_ctu;
    
    
    wire [AXI_CACHE_DATA_WDTH -1:0] axi_wdata_b[4:0];
    parameter Y_DIV_WIDTH = YY_WIDTH/CL_AXI_DIV_FAC;
    parameter CB_DIV_WIDTH = CH_WIDTH/CL_AXI_DIV_FAC;
   generate  
      if(CL_AXI_DIV_FAC==1) begin
         assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],cb_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]};
      end else if(CL_AXI_DIV_FAC==2) begin
         assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],cb_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]};
         assign axi_wdata_b[1] = {cr_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],cb_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],yy_pixels_8x8[Y_DIV_WIDTH*2-1:Y_DIV_WIDTH*1]};
      end else if(CL_AXI_DIV_FAC==3) begin
         if(BIT_DEPTH == 8 ) begin
            assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],cb_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],yy_pixels_8x8[Y_DIV_WIDTH*1+2-1:Y_DIV_WIDTH*0]};
            assign axi_wdata_b[1] = {cr_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],cb_pixels_8x8[CB_DIV_WIDTH*2+2-1:CB_DIV_WIDTH*1],yy_pixels_8x8[Y_DIV_WIDTH*2+2-1:Y_DIV_WIDTH*1+2]};
            assign axi_wdata_b[2] = {cr_pixels_8x8[CB_DIV_WIDTH*3+2-1:CB_DIV_WIDTH*2],cb_pixels_8x8[CB_DIV_WIDTH*3+2-1:CB_DIV_WIDTH*2+2],yy_pixels_8x8[Y_DIV_WIDTH*3+2-1:Y_DIV_WIDTH*2+2]};
         end
         else if((BIT_DEPTH == 10)) begin
            assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],cb_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],yy_pixels_8x8[Y_DIV_WIDTH*1+1-1:Y_DIV_WIDTH*0]};
            assign axi_wdata_b[1] = {cr_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],cb_pixels_8x8[CB_DIV_WIDTH*2+2-1:CB_DIV_WIDTH*1],yy_pixels_8x8[Y_DIV_WIDTH*2+1-1:Y_DIV_WIDTH*1+1]};
            assign axi_wdata_b[2] = {cr_pixels_8x8[CB_DIV_WIDTH*3+2-1:CB_DIV_WIDTH*2],cb_pixels_8x8[CB_DIV_WIDTH*3+2-1:CB_DIV_WIDTH*2+2],yy_pixels_8x8[Y_DIV_WIDTH*3+1-1:Y_DIV_WIDTH*2+1]};
         end
         else begin // 420 12bit
            assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],cb_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]};
            assign axi_wdata_b[1] = {cr_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],cb_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],yy_pixels_8x8[Y_DIV_WIDTH*2-1:Y_DIV_WIDTH*1]};
            assign axi_wdata_b[2] = {cr_pixels_8x8[CB_DIV_WIDTH*3-1:CB_DIV_WIDTH*2],cb_pixels_8x8[CB_DIV_WIDTH*3-1:CB_DIV_WIDTH*2],yy_pixels_8x8[Y_DIV_WIDTH*3-1:Y_DIV_WIDTH*2]};
         end
      end else if(CL_AXI_DIV_FAC==4) begin
         assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],cb_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0],yy_pixels_8x8[Y_DIV_WIDTH*1-1:Y_DIV_WIDTH*0]};
         assign axi_wdata_b[1] = {cr_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],cb_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1],yy_pixels_8x8[Y_DIV_WIDTH*2-1:Y_DIV_WIDTH*1]};
         assign axi_wdata_b[2] = {cr_pixels_8x8[CB_DIV_WIDTH*3-1:CB_DIV_WIDTH*2],cb_pixels_8x8[CB_DIV_WIDTH*3-1:CB_DIV_WIDTH*2],yy_pixels_8x8[Y_DIV_WIDTH*3-1:Y_DIV_WIDTH*2]};
         assign axi_wdata_b[3] = {cr_pixels_8x8[CB_DIV_WIDTH*4-1:CB_DIV_WIDTH*3],cb_pixels_8x8[CB_DIV_WIDTH*4-1:CB_DIV_WIDTH*3],yy_pixels_8x8[Y_DIV_WIDTH*4-1:Y_DIV_WIDTH*3]};
      end else if(CL_AXI_DIV_FAC==5) begin
         assign axi_wdata_b[0] = {cr_pixels_8x8[CB_DIV_WIDTH*1-1:CB_DIV_WIDTH*0]    ,cb_pixels_8x8[CB_DIV_WIDTH*1+1-1:CB_DIV_WIDTH*0],  yy_pixels_8x8[Y_DIV_WIDTH*1+1-1:Y_DIV_WIDTH*0]};
         assign axi_wdata_b[1] = {cr_pixels_8x8[CB_DIV_WIDTH*2-1:CB_DIV_WIDTH*1]    ,cb_pixels_8x8[CB_DIV_WIDTH*2+2-1:CB_DIV_WIDTH*1+1],yy_pixels_8x8[Y_DIV_WIDTH*2+2-1:Y_DIV_WIDTH*1+1]};
         assign axi_wdata_b[2] = {cr_pixels_8x8[CB_DIV_WIDTH*3-1:CB_DIV_WIDTH*2]    ,cb_pixels_8x8[CB_DIV_WIDTH*3+3-1:CB_DIV_WIDTH*2+2],yy_pixels_8x8[Y_DIV_WIDTH*3+3-1:Y_DIV_WIDTH*2+2]};
         assign axi_wdata_b[3] = {cr_pixels_8x8[CB_DIV_WIDTH*4+1-1:CB_DIV_WIDTH*3]  ,cb_pixels_8x8[CB_DIV_WIDTH*4+3-1:CB_DIV_WIDTH*3+3],yy_pixels_8x8[Y_DIV_WIDTH*4+3-1:Y_DIV_WIDTH*3+3]};
         assign axi_wdata_b[4] = {cr_pixels_8x8[CB_DIV_WIDTH*5+3-1:CB_DIV_WIDTH*4+1],cb_pixels_8x8[CB_DIV_WIDTH*5+3-1:CB_DIV_WIDTH*4+3],yy_pixels_8x8[Y_DIV_WIDTH*5+3-1:Y_DIV_WIDTH*4+3]};
      end
   endgenerate
//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------
	 assign                 axi_awid     = 0;
	 assign                 axi_awlen    = PIX_REF_AXI_AX_LEN;
	 assign                 axi_awsize   = PIX_REF_AXI_AX_SIZE;
	 assign                 axi_awburst  = `AX_BURST_INC;
	 assign    	            axi_awlock   = `AX_LOCK_DEFAULT;
	 assign                 axi_awcache  = `AX_CACHE_DEFAULT;
	 assign                 axi_awprot   = `AX_PROT_DATA;    

	assign		{	Xc_out_8x8,Yc_out_8x8,
					yy_pixels_8x8,cb_pixels_8x8,cr_pixels_8x8} = fifo_data_in;
					
	assign y_8x8_in_ctu = Yc_out_8x8[CTB_SIZE_WIDTH - C_L_V_SIZE - 1:0];
	assign x_8x8_in_ctu = Xc_out_8x8[CTB_SIZE_WIDTH - C_L_H_SIZE - 1:0];
	
	assign x_ctu = Xc_out_8x8[X11_ADDR_WDTH - C_L_H_SIZE - 1:CTB_SIZE_WIDTH - C_L_H_SIZE ];
	assign y_ctu = Yc_out_8x8[X11_ADDR_WDTH - C_L_V_SIZE - 1:CTB_SIZE_WIDTH - C_L_V_SIZE ];
		
   assign axi_wstrb_nxt = = (CACHE_LINE_WDTH*BIT_DEPTH-1)/AXI_CACHE_DATA_WDTH;
                        
		// synthesis translate_off
ref_buff_fifo_monitor
#
(
	.FILE_NAME  ("BQSquare_416x240_60_qp37_416x240_8bit_final_dec_order.yuv"),
`ifdef VERIFY_NONE
	.OUT_VERIFY (0),
`else
	.OUT_VERIFY (1),
`endif
	.DEBUG 		(0)
)monitor_block
(
		.clk			(clk),
		.reset			(reset),
		.empty			(fifo_is_empty_in),
		.Xc_out_8x8		(Xc_out_8x8),
		.Yc_out_8x8		(Yc_out_8x8),
		.yy_pixels_8x8	(yy_pixels_8x8),
		.cb_pixels_8x8	(cb_pixels_8x8),
		.cr_pixels_8x8	(cr_pixels_8x8),
		.pic_width_in	(pic_width_in),
		.pic_height_in	(pic_height_in),
		.rd_en         	(fifo_rd_en_out)
);
	// synthesis translate_on
	
	
	 always@(posedge clk) begin
		if(Xc_out_8x8 == 0 && Yc_out_8x8 == 0 && fifo_is_empty_in==0) begin
			current_pic_dpb_base_addr_d <= dpb_axi_addr_in;
		end
	 end
	 
	 always@(*) begin
		if(Xc_out_8x8==0 && Yc_out_8x8==0) begin
			current_pic_dpb_base_addr_use  = dpb_axi_addr_in;
		end
		else begin
			current_pic_dpb_base_addr_use = current_pic_dpb_base_addr_d;
		end
	 end
	 


    always@(*) begin
         fifo_rd_en_out = 0;
        case(state_axi_write)
			STATE_AXI_WRITE_RESP: begin
				//if(axi_bvalid) begin
				if(axi_wready) begin
					//if(axi_bresp == `XRESP_SLAV_ERROR || axi_bid !=0) begin   
						// dont assert read enable if there is an error
					//end
					//else begin
						fifo_rd_en_out = 1;
					//end
				end
			end
        endcase
    end
    
   //always@(*) begin
   assign  axi_bready = 1;
   //end
    
    always@(posedge clk) begin
        if (reset) begin
            state_axi_write <= STATE_AXI_WRITE_ADDRESS_SEND;
            axi_awvalid <= 0;
            axi_wvalid <= 0;
            // axi_bready <= 0;
            burst_counter <= 0;
            axi_wstrb <= 64'h0000_0000_0000_0000;
        end
        else begin
            case(state_axi_write)
                STATE_AXI_WRITE_ADDRESS_SEND: begin
                    if(!fifo_is_empty_in) begin
                        axi_awaddr <= current_pic_dpb_base_addr_use + (y_ctu * `REF_PIX_IU_ROW_OFFSET)+ (x_ctu*`REF_PIX_IU_OFFSET) +  (y_8x8_in_ctu* `REF_PIX_BU_ROW_OFFSET) + (x_8x8_in_ctu* `REF_PIX_BU_OFFSET);
                        axi_awvalid <= 1;
                        state_axi_write <= STATE_AXI_WRITE_ADDRESS_SEND_WAIT;
                    end  
                    else begin
                        axi_awvalid <= 0;
                    end
                    // axi_bready <= 0;
                    axi_wvalid <= 0;
                    burst_counter <= 0;
                    axi_wlast <= 0;
                end
                STATE_AXI_WRITE_ADDRESS_SEND_WAIT: begin
                    if(axi_awready) begin
                        axi_awvalid <= 0;
                        if(burst_counter == axi_awlen) begin
                           axi_wlast <= 1;
                        end
                        burst_counter <= burst_counter + 1;
                        axi_wstrb <= axi_wstrb_nxt;
                        axi_wdata <= axi_wdata_b[burst_counter];
                        axi_wvalid <= 1;
                        state_axi_write <= STATE_AXI_WRITE_WAIT;
                    end
                end
                STATE_AXI_WRITE_WAIT: begin
                    if(axi_wready) begin
                        axi_wdata <= axi_wdata_b[burst_counter];
                        axi_wstrb <= axi_wstrb_nxt;
                        // axi_bready <= 1;
                        burst_counter <= burst_counter + 1;
                        if(burst_counter == axi_awlen) begin
                           state_axi_write <= STATE_AXI_WRITE_RESP;
                           axi_wlast <= 1;
                        end
                    end
                end
                STATE_AXI_WRITE_RESP: begin
                    if(axi_wready) begin
                        axi_wvalid <= 0;
                        state_axi_write <= STATE_AXI_WRITE_ADDRESS_SEND;
                    end
                    
                    // if(axi_bvalid) begin
                        // if(axi_bresp == `XRESP_SLAV_ERROR || axi_bid !=0) begin
                            // state_axi_write <= STATE_AXI_WRITE_ADDRESS_SEND_WAIT;
                            // axi_awvalid <= 1;            
                            // burst_counter <= 0;
                            // axi_wlast <= 0;
                        // end
                        // else begin
                            // axi_bready <= 0;
                            
                        // end
                    // end
                end
                
            endcase
        end
    end
    
    

endmodule