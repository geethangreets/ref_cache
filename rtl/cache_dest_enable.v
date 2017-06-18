`timescale 1ns / 1ps
module cache_dest_enable
(
   x_addr      ,
   y_addr      ,
   start_x     ,
   start_y     ,
   blk_width   ,
   blk_height  ,
   dest_enable
);

   
    `include "../sim/cache_configs_def.v"
    `include "../sim/pred_def.v"
    `include "../sim/inter_axi_def.v"
    
   parameter   NOW_X_WDTH = X_ADDR_WDTH - C_L_H_SIZE;
   parameter   NOW_Y_WDTH = Y_ADDR_WDTH - C_L_V_SIZE;
   parameter   START_X_WDTH = X_ADDR_WDTH;
   parameter   START_Y_WDTH = Y_ADDR_WDTH;
   parameter   XXMA_DIM_WDTH = 4;
   parameter   XXMA_DIM_HIGT = 4;
   parameter   SHIFT_H = C_L_H_SIZE;
   parameter   SHIFT_V = C_L_V_SIZE;
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------

   input [NOW_X_WDTH -1 :0]                       x_addr;
   input [NOW_Y_WDTH -1 :0]                       y_addr;
   input [START_X_WDTH-1:0]                       start_x;
   input [START_Y_WDTH-1:0]                       start_y;
   input [XXMA_DIM_WDTH-1:0]                      blk_width;
   input [XXMA_DIM_HIGT-1:0]                      blk_height;
   output reg                                     dest_enable;
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------    

   reg dest_enable_y;
   reg dest_enable_x;

//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

always @(* ) begin 
    if ( ((y_addr << SHIFT_V) <= (start_y  + blk_height) ) && (( (y_addr+1'b1) << SHIFT_V) > start_y )) begin
        dest_enable_y = 1;
    end
    else begin
        dest_enable_y = 0;
    end
end

always @(* ) begin 
    if ( ((x_addr << SHIFT_H) <= (start_x + blk_width) ) && (( (x_addr+1'b1) << SHIFT_H) > start_x )) begin
        dest_enable_x = 1;
    end
    else begin
        dest_enable_x = 0;
    end
end

always @(* ) begin 
    if( dest_enable_x && dest_enable_y) begin
        dest_enable = 1;
    end
    else begin
        dest_enable = 0;
    end
end


endmodule