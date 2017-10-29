`timescale 1ns / 1ps
module geet_fifo_almost_full(

	clk,
    reset,
	wr_en, 
	rd_en, 
	d_in, 
	d_out, 
	empty, 
	almost_full,
	program_full,
	full
);
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
    parameter FIFO_DATA_WIDTH = 32;
    parameter LOG2_FIFO_DEPTH = 6;
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input clk;
    input reset;
    input wr_en;		// write enable	
	input rd_en;		// read enable			// data input port
    input  [FIFO_DATA_WIDTH-1:0] d_in;
    output reg [FIFO_DATA_WIDTH-1:0] d_out;
    output reg full;
    output reg almost_full;
    output reg program_full;
    output reg empty;

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------
	 
    reg                       wr_en_d;		// write enable	
    reg [LOG2_FIFO_DEPTH-1:0] wr_pointer;			// buffer size of 16
    reg [LOG2_FIFO_DEPTH-1:0] rd_pointer;
    reg [LOG2_FIFO_DEPTH-1:0] rd_pointer2;
    reg [FIFO_DATA_WIDTH-1:0] internal [(1<<LOG2_FIFO_DEPTH)-1:0];
    wire [LOG2_FIFO_DEPTH-1:0] occupancy;
    
    wire [LOG2_FIFO_DEPTH-1:0] next_rd_pointer = rd_pointer + 1'b1;
    wire [LOG2_FIFO_DEPTH-1:0] next_wr_pointer = wr_pointer + 1'b1;
    
    
    assign occupancy = (wr_pointer>rd_pointer ) ? (wr_pointer-rd_pointer) : ((1<<LOG2_FIFO_DEPTH) - (wr_pointer-rd_pointer));
//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

// Instantiate the module

always@(*) begin
   rd_pointer2 = rd_pointer;
   if(rd_en) begin
      rd_pointer2 = next_rd_pointer;
   end
end

// always@(*) begin
   // d_out = internal[rd_pointer];
// end

always@(posedge clk) begin 
    if (reset) begin
      empty <= 1;
      rd_pointer <= 0;
    end
    else begin
         case({wr_en_d,rd_en})
            2'b10: begin
               if(!full) begin
                  empty <= 0;
               end
            end
            2'b01: begin
               if(!empty) begin
                  rd_pointer <= next_rd_pointer;
                  if((next_rd_pointer) == wr_pointer) begin
                     empty <= 1;
                  end
               end
            end
            2'b11: begin    
               rd_pointer <= next_rd_pointer;
               if((next_rd_pointer) == wr_pointer) begin
                  empty <= 1;
               end
            end
         endcase
    end
end


always@(posedge clk) begin    
    if (reset) begin
      full <= 0;
      wr_pointer <= 0;
      almost_full <= 0;
      program_full <= 0;
   end
   else begin
      case({wr_en,rd_en})
            2'b10: begin
               if(!full) begin
                  wr_pointer <= next_wr_pointer;
                  if((next_wr_pointer) == rd_pointer) begin
                     full <= 1;
                  end
                  if(next_wr_pointer + 1'b1 == rd_pointer) begin
                     almost_full <= 1;
                  end
                  if(next_wr_pointer + 2'd2 == rd_pointer) begin
                     program_full <= 1;
                  end
               end
            end
            2'b01: begin
               if(!empty) begin
                  full <= 0;
                  if((next_wr_pointer) == rd_pointer) begin
                     almost_full <= 0;
                  end
                  if((next_wr_pointer+ 1'b1) == rd_pointer) begin
                     program_full <= 0;
                  end
               end
            end
            2'b11: begin    
                wr_pointer <= next_wr_pointer;
            end
        endcase
    end
end

always@(posedge clk) begin
   if((wr_en ) ) begin
      internal[wr_pointer] <= d_in;
   end
   d_out <= internal[rd_pointer2];
end

always@(posedge clk) begin
   wr_en_d <= wr_en; 
end

// synthesis translate_off
always@(posedge clk) begin
	if(full & wr_en) begin
		$display("%d write when full %m",$time);
		$stop;
	end
	if(empty & rd_en) begin
		$display("%d read when empty %m",$time);
		$stop;
	end
end
// synthesis translate_on
endmodule