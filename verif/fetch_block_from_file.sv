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
// Description: /* This module instantly returns pixel values from the given yuv file for given x,y poc address */
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2

module fetch_block_from_file(
    clk,
    reset,
    x_address_in,
    y_address_in,
	pic_poc_in,
	valid_in,
	lu_pixel_blk_out,
    cb_pixel_blk_out,
    cr_pixel_blk_out
	
);
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------

`include "format_def.v"

//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------

    parameter  BLOCK_HORI_SIZE                   = 8;
    parameter  BLOCK_VERT_SIZE                   = 8;
    parameter  IMG_WIDTH                         = 1920;
    parameter  IMG_HEIGHT                        = 1080;
    parameter  FILE_NAME                         = "";
   
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------
    localparam  BLOCK_HORI_SIZE_CH               = BLOCK_HORI_SIZE/C_SUB_WIDTH;
    localparam  BLOCK_VERT_SIZE_CH               = BLOCK_VERT_SIZE/C_SUB_HEIGHT;

    localparam LU_SIZE   =  IMG_WIDTH * IMG_HEIGHT;
    localparam CB_SIZE   = (IMG_WIDTH / C_SUB_WIDTH) * (IMG_HEIGHT / C_SUB_HEIGHT);
    localparam CR_SIZE   = (IMG_WIDTH / C_SUB_WIDTH) * (IMG_HEIGHT / C_SUB_HEIGHT);
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input           clk;
    input           reset;
    input           valid_in;
    input [31:0]    x_address_in;
    input [31:0]    y_address_in;
    input [31:0]    pic_poc_in;

    output reg [BIT_DEPTH* BLOCK_HORI_SIZE* BLOCK_VERT_SIZE -1:0]            lu_pixel_blk_out;
    output reg [BIT_DEPTH* BLOCK_HORI_SIZE_CH* BLOCK_VERT_SIZE_CH -1:0]      cb_pixel_blk_out;
    output reg [BIT_DEPTH* BLOCK_HORI_SIZE_CH* BLOCK_VERT_SIZE_CH -1:0]      cr_pixel_blk_out;

    integer file_in, position, i, j, scan_file;
    reg [BIT_DEPTH-1:0] raw_img_blk;
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------
initial begin
    file_in = $fopen(FILE_NAME,"rb");
    if(file_in) begin    
        position = $fseek(file_in, 0, `SEEK_SET);
    end
    else begin
        $display("%m file not open!! file name:%s", FILE_NAME);
        $stop;
    end
end


//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------
always@(*)begin
    if(valid_in) begin
        for(i = 0; i < BLOCK_VERT_SIZE; i = i + 1) begin
            position = $fseek(file_in, (pic_poc_in) * (LU_SIZE + CB_SIZE + CR_SIZE) + x_address_in + (y_address_in + i) * IMG_WIDTH, 0);
            for(j = 0; j < BLOCK_HORI_SIZE; j = j + 1) begin
                scan_file = $fread(raw_img_blk, file_in);
                lu_pixel_blk_out[(i*BLOCK_HORI_SIZE+j)*BIT_DEPTH +: BIT_DEPTH] <= raw_img_blk;
                // TODO add filling up CB and CR blocks
            end
        end
    end
  
end  


endmodule