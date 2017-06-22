`timescale 1ns / 1ps
module inf_monitor(
    clk,
    reset,
    data1,
	valid,
	ready
);
//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
	parameter WIDTH 		= 8;
	parameter FILE_NAME           = "";
    parameter OUT_VERIFY  = 1;
	parameter SKIP_ZERO  = 0;  // if file reads a word as all zero and if it mismatches don't stop the simulation
	parameter DEBUG = 0;
   
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input clk;
    input reset;
	input  valid,ready; 
    input [WIDTH-1:0] 	data1;
	
// synthesis translate_off
	integer file_in;
	integer i,j;
	reg [7:0] temp;
    reg wrong_compare;
	
    wire [7:0] data1_arry[WIDTH/8-1:0];
	reg [WIDTH-1:0] temp_word;
	integer address;
   
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

// Instantiate the module

generate
        genvar ii;
        for (ii = 0 ; ii < WIDTH/8 ; ii = ii + 1) begin
				assign  data1_arry[ii]= data1[(ii+1)*8-1:ii*8];
        end
endgenerate

initial begin
	if(OUT_VERIFY) begin
		file_in = $fopen(FILE_NAME,"rb");
		if(file_in) begin
			
		end
		else begin
			$display("file not open!!");
			$stop;
		end
	end
end


always@(posedge clk) begin
   if(reset) begin
		address <= 0;
        wrong_compare <= 0;
	end
	else begin
        wrong_compare <= 0;
		if(valid & ready) begin
				if(DEBUG ==1) begin
					$display("%d read from inf %x @%d %m",$time,data1,address);
					address <= address + 1;
				end
				if(OUT_VERIFY) begin
					for(i=0; i<WIDTH/8;i=i+1) begin
						temp = $fgetc(file_in);
                        for (j=0;j<8;j=j+1) begin
                            temp_word[i*8+j] = temp[j];
                        end
                        
						if(temp == data1_arry[i]) begin
							if(DEBUG ==1) begin
								$display("%d compare success in %m",$time);
							end
						end						
						else begin
							$display("%d compare fail hard %x soft %x in %m",$time, data1_arry[i], temp);
                            wrong_compare <= 1;
						end
					end
				end
		end

        if(wrong_compare==1) begin
            if(SKIP_ZERO==0) begin
                $stop;
            end
            else begin
                if(temp_word[WIDTH-1:WIDTH/2] ==0 || temp_word[WIDTH/2-1:0] ==0) begin
                end
                else begin
                    $stop;
                end
            end
        end
	end
end
// synthesis translate_on
endmodule