`timescale 1ns / 1ps
 //////////////////////////////////////////////////////////////////////////////////
// Company: ParaQum Tech
// Engineer: Geethan Karunaratne
// 
// Create Date: 
// Design Name: HEVC ENCODER CACHE
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: /* This module emulates issuing request to cache  depending on the write back block completion*/
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module request_issuer(
    clk,
    reset,
    cache_idle_in,
    cache_valid_out,
    cache_req_data_out,
    write_back_en_out,
    write_back_ack_in,
    write_back_data
);
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
`include "../sim/pred_def.v"

//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
    parameter   BLOCK_SIZE      = 8;
    parameter   CTU_SIZE        = 64;
    parameter   IMG_WIDTH                         = 1920;
    parameter   IMG_HEIGHT                        = 1080;   
    parameter   X_FILE_WIDTH    = 32;
   
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input clk;
    input reset;
    
    input                           cache_idle_in;
    output reg                      cache_valid_out;
    output [X_FILE_WIDTH*2-1:0]     cache_req_data_out;
    
    input                                               write_back_ack_in;
    output  reg                                         write_back_en_out;
    output [(X_ADDR_WDTH -LOG2_MIN_DU_SIZE)*2 + (BIT_DEPTH * BLOCK_SIZE * BLOCK_SIZE) -1 :0]  write_back_data;
   
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

    integer state; 
    logic xy_driver_ready;      // driven by internal state machine that checks request xy
    logic xy_driver_valid;
    logic [X_FILE_WIDTH*2-1:0]              file_rdata;
    
    logic [31:0] cur_x_idx;
    logic [31:0] cur_y_idx;
    logic [31:0] next_x_idx;
    logic [31:0] next_y_idx;
    
    logic [31:0] inner_cur_x_idx;
    logic [31:0] inner_cur_y_idx;
    logic [31:0] inner_next_x_idx;
    logic [31:0] inner_next_y_idx;

    logic [31:0] outer_cur_x_idx;
    logic [31:0] outer_cur_y_idx;
    logic [31:0] outer_next_x_idx;
    logic [31:0] outer_next_y_idx;
    logic [31:0] cur_poc_idx;
    logic [31:0] next_poc_idx;
    
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_x_in;	
	logic signed [MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0] 	luma_ref_start_y_in;

	wire [PIXEL_WIDTH*DBF_OUT_Y_BLOCK_SIZE*DBF_OUT_Y_BLOCK_SIZE -1:0] 	yy_pixels_8x8;
    
//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------
//////////// INTERFACE DRIVERS /////////////////

fifo_write_driver 
#(
    .WIDTH (X_FILE_WIDTH*2),
    .RESET_TIME (100),
    .VALID_FIRST(1),
    .FILE_NAME("../simvectors/ibc_cache_request.bin")
)

xy_request_driver(
    .clk         (clk)                     ,
    .reset       (reset)                  ,
    .out         (file_rdata)     ,
    .ready       (xy_driver_ready)       ,
    .address     (),
    .wr_en       (xy_driver_valid)        
);

fetch_block_from_file
# (
    .FILE_NAME ("../simvectors/reconstructed_full.yuv"),
    .BLOCK_HORI_SIZE(BLOCK_SIZE),
    .BLOCK_VERT_SIZE(BLOCK_SIZE),
    .IMG_WIDTH      (IMG_WIDTH),
    .IMG_HEIGHT     (IMG_HEIGHT)
)
yuv_freader
(
    .clk                (clk)    ,
    .reset              (reset)    ,
    .valid_in           (write_back_en_out)    ,
    .x_address_in       (BLOCK_SIZE*cur_x_idx)    ,
    .y_address_in       (BLOCK_SIZE*cur_y_idx)    ,
	.pic_poc_in         (cur_poc_idx)    ,
	.lu_pixel_blk_out   (yy_pixels_8x8)    ,
    .cb_pixel_blk_out ()    ,
    .cr_pixel_blk_out ()
	
);

assign write_back_data = {cur_x_idx[X_ADDR_WDTH -LOG2_MIN_DU_SIZE -1: 0],cur_y_idx[X_ADDR_WDTH -LOG2_MIN_DU_SIZE -1: 0],yy_pixels_8x8};
assign {luma_ref_start_x_in} = file_rdata[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1:0];
assign {luma_ref_start_y_in} = file_rdata[MVD_WIDTH - MV_L_FRAC_WIDTH_HIGH -1+X_FILE_WIDTH:0+X_FILE_WIDTH];
assign cache_req_data_out = {file_rdata};

assign inner_next_x_idx = (inner_cur_x_idx < (CTU_SIZE/BLOCK_SIZE)-1) ? inner_cur_x_idx + 1 : 0;
assign inner_next_y_idx = (inner_cur_x_idx < (CTU_SIZE/BLOCK_SIZE)-1) ? inner_cur_y_idx : ((inner_cur_y_idx < (CTU_SIZE/BLOCK_SIZE)-1) ?inner_cur_y_idx + 1: 0);

assign outer_next_x_idx = ((inner_cur_x_idx < (CTU_SIZE/BLOCK_SIZE)-1) || (inner_cur_y_idx < (CTU_SIZE/BLOCK_SIZE)-1))  ? (outer_cur_x_idx) : ((outer_cur_x_idx < (IMG_WIDTH/BLOCK_SIZE)-BLOCK_SIZE) ? outer_cur_x_idx + (CTU_SIZE/BLOCK_SIZE) : 0);
assign outer_next_y_idx = ((inner_cur_x_idx < (CTU_SIZE/BLOCK_SIZE)-1) || (inner_cur_y_idx < (CTU_SIZE/BLOCK_SIZE)-1))  ? (outer_cur_y_idx) : ((outer_cur_x_idx < (IMG_WIDTH/BLOCK_SIZE)-BLOCK_SIZE) ? outer_cur_y_idx : outer_cur_y_idx + (CTU_SIZE/BLOCK_SIZE)); 

assign next_x_idx = inner_next_x_idx + outer_next_x_idx;
assign next_y_idx = inner_next_y_idx + outer_next_y_idx;

assign next_poc_idx = ((cur_y_idx == (IMG_HEIGHT/BLOCK_SIZE)-1) && (cur_x_idx == (IMG_WIDTH/BLOCK_SIZE)-1) )? cur_poc_idx  + 1 : cur_poc_idx ;

// assign next_x_idx = (cur_x_idx < (IMG_WIDTH/BLOCK_SIZE)-1) ? cur_x_idx + 1 : 0;
// assign next_y_idx = (cur_x_idx < (IMG_WIDTH/BLOCK_SIZE)-1) ? cur_y_idx : cur_y_idx + 1;
// assign next_poc_idx = ((cur_y_idx == (IMG_HEIGHT/BLOCK_SIZE)-1) && (cur_x_idx == (IMG_WIDTH/BLOCK_SIZE)-1) )? cur_poc_idx  + 1 : cur_poc_idx ;
    always@(posedge clk) begin
        if(reset) begin
            inner_cur_x_idx <= 'd0;
            outer_cur_x_idx <= 'd0;
            cur_x_idx       <= 'd0;
            inner_cur_y_idx <= 'd0;
            outer_cur_y_idx <= 'd0;
            cur_y_idx       <= 'd0;
            cur_poc_idx <= 'd0;
            state <= 'd0;
        end
        else begin
            case(state)
                0: begin
                    if(xy_driver_valid) begin
                        if (( ((cur_x_idx*BLOCK_SIZE) > (luma_ref_start_x_in) ) && ((cur_y_idx*BLOCK_SIZE) > (luma_ref_start_y_in)) ) ||
                        (((cur_y_idx*BLOCK_SIZE) > (luma_ref_start_y_in+CTU_SIZE))) )begin
                            state <= 1;
                        end
                        else begin
                            if(write_back_ack_in) begin
                                inner_cur_x_idx <= inner_next_x_idx;
                                outer_cur_x_idx <= outer_next_x_idx;
                                cur_x_idx       <= next_x_idx;
                                inner_cur_y_idx <= inner_next_y_idx;
                                outer_cur_y_idx <= outer_next_y_idx;
                                cur_y_idx       <= next_y_idx;
                                cur_poc_idx <= next_poc_idx;
                            end
                        end                    
                    end
                end 
                1: begin
                    if(xy_driver_valid & cache_idle_in) begin
                        state <= 0;
                    end
                end

            endcase
        
        end
    end
    
    always@(*) begin
        write_back_en_out = 0;
        xy_driver_ready = 0;
        cache_valid_out = 0;
        case(state)
            0: begin
                if(xy_driver_valid) begin
                    if (( ((cur_x_idx*BLOCK_SIZE) > (luma_ref_start_x_in) ) && ((cur_y_idx*BLOCK_SIZE)> (luma_ref_start_y_in)) ) || 
                    (((cur_y_idx*BLOCK_SIZE) > (luma_ref_start_y_in+CTU_SIZE))))begin

                    end
                    else begin
                        write_back_en_out = 1;
                    end                    
                end            
            end
            1: begin
                if(xy_driver_valid & cache_idle_in) begin
                    cache_valid_out = 1;   
                    xy_driver_ready = 1;                    
                end
            end
        endcase
    end


endmodule