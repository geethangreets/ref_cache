`timescale 1ns / 1ps
module fifo_write_driver(
    clk,
    reset,
    out ,
	ready,
    address,
	wr_en
);
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
	parameter WIDTH 		= 8;
	parameter FILE_NAME     = "";
    parameter EMPTY_MODEL   = 0;
    parameter VALID_FIRST   = 1;
    parameter RESET_TIME    = 10;
	parameter END_ADDRESS   = 2147483640;
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input clk;
    input reset;
	input ready; 
    output reg wr_en;
    output [WIDTH-1:0]  out;
    output reg [32-1:0] address;
	
// synthesis translate_off
	integer file_in;
	integer i;
	reg [7:0] temp;
	
	reg [7:0] out_arry[WIDTH/8-1:0];
	
	integer reset_counter ;
	
	integer write_wait_counter;
	integer write_upper_lim;
	integer write_state;
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

// Instantiate the module

generate
        genvar ii;
        for (ii = 0 ; ii < WIDTH/8 ; ii = ii + 1) begin : row_iteration
				assign  out[(ii+1)*8-1:ii*8] = out_arry[ii];
        end
endgenerate

initial begin
	reset_counter = 0;
	file_in = $fopen(FILE_NAME,"rb");
	if(file_in) begin
        for(i=0; i<WIDTH/8;i=i+1) begin
            out_arry[i] <= 8'b0;
        end		
	end
	else begin
		$display("%m %s file not open!!",FILE_NAME);
		$stop;
	end
end

always@(posedge clk) begin
	if(reset) begin
		reset_counter <= 0; 
	end
	else begin
		if(reset_counter <RESET_TIME) begin
			reset_counter <= reset_counter + 1; 
		end
	end
end

always@(posedge clk) begin    
	if(reset_counter < RESET_TIME) begin
		write_state <= 0;
        address <= {32{1'b0}};
	end
	else begin
		case(write_state) 
			0: begin
                if(VALID_FIRST==1) begin
                    for(i=0; i<WIDTH/8;i=i+1) begin
                        out_arry[i] <= $fgetc(file_in);
                    end 
                end
				write_state <= 1;
			end
			1: begin
                if(address < END_ADDRESS) begin
    				if(wr_en & ready) begin
                        for(i=0; i<WIDTH/8;i=i+1) begin
                            out_arry[i] <= $fgetc(file_in);
                        end
                        address <= address + 1;
                    end
                end
			end
		endcase
	end
end

always@(*) begin
    if(reset) begin
        wr_en = 0;
    end
    else begin
        wr_en = 0;
        case(write_state)
            1: begin
                if(address < END_ADDRESS) begin
                    wr_en = 1; 
                end
            end
        endcase
    end
end
// synthesis translate_on
endmodule