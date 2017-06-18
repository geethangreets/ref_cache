`timescale 1ns / 1ps
module age_memory
(
    clk,
	reset,
    r_addr_in,
	w_addr_in,
	r_data_out,
	w_data_in,
	w_en_in
	//r_en_in

);
    `include "../sim/pred_def.v"
    `include "../sim/cache_configs_def.v"
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
	parameter							AGE_BANK_LEN = SET_ADDR_WDTH;
    
	
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    localparam                          STATE_CLEAR				        = 0;    // the state that is entered upon reset
    localparam                          STATE_NORMAL	                = 1;
   	
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    

   input                           		         clk;
	input													   reset;
	input	[(1<<C_N_WAY)*C_N_WAY-1:0]      		   w_data_in;
	input	[SET_ADDR_WDTH -1:0]							r_addr_in;			// read 8 ages at once 
	input	[SET_ADDR_WDTH -1:0]							w_addr_in;			
	input													   w_en_in;
    //input                                     r_en_in;
	output  [(1<<C_N_WAY)*C_N_WAY-1:0]		      r_data_out;
	reg [(1<<C_N_WAY)*C_N_WAY-1:0]			      r_data_out_reg;
	


	//---------------------------------------------------------------------------------------------------------------------
    // Internal wires and registers
    //---------------------------------------------------------------------------------------------------------------------
  

    reg         [C_N_WAY*(1<<C_N_WAY)-1:0]      		mem [(1<<AGE_BANK_LEN)-1:0];
	//reg			[SET_ADDR_WDTH - Y_BANK_BITS-1:0]		out_address;
	reg [SET_ADDR_WDTH-1:0]                        	   count;
    // reg                                            all_clear;
	reg state;
	
	reg	[(1<<C_N_WAY)*C_N_WAY-1:0]      				w_data;
	reg	[SET_ADDR_WDTH -1:0]							   w_addr;	
	reg													      w_en;	

    //---------------------------------------------------------------------------------------------------------------------
    // Implmentation
    //---------------------------------------------------------------------------------------------------------------------
	// always @(posedge clk) begin
		// if(reset) begin
			// count <= 0;
			// state <= STATE_CLEAR;
		// end
		// else begin
			// case(state) 
				// STATE_CLEAR: begin
					// if(count == AGE_BANK_LEN) begin
						// state <= STATE_NORMAL;
					// end
					// else begin
						// mem[count] <= count[2:0];
                        // count <= count + 1;
					// end
				// end
				// STATE_NORMAL: begin
					// if(w_en_in) begin
						// mem[w_addr_in] <= w_data_in;
					// end
				// end
			// endcase
		// end
	// end	
	
	// assign 	r_data_out = {	mem[{r_addr_in,3'b000}],
							// mem[{r_addr_in,3'b001}],
							// mem[{r_addr_in,3'b010}],
							// mem[{r_addr_in,3'b011}],
							// mem[{r_addr_in,3'b100}],
							// mem[{r_addr_in,3'b101}],
							// mem[{r_addr_in,3'b110}],
							// mem[{r_addr_in,3'b111}]};    
    
	assign r_data_out = r_data_out_reg;
	always @(posedge clk) begin
		if(reset) begin
			count <= 0;
			state <= STATE_CLEAR;
		end
		else begin
			case(state) 
				STATE_CLEAR: begin                        
                        count <= count + 1'b1;
						if(count == {(SET_ADDR_WDTH){1'b1}}) begin
							state <= STATE_NORMAL;
						end

				end
				STATE_NORMAL: begin

				end
			endcase
		end
	end	
	
	always @(*) begin
		if(reset) begin
			w_data = 	{((1<<C_N_WAY)*C_N_WAY){1'bx}};
			w_addr = 	{(SET_ADDR_WDTH){1'bx}};
			w_en   = 	1'b0;
		end
		else begin
			case(state) 
				STATE_CLEAR: begin
						w_data = 	{ 	3'd0,
                                        3'd1,
                                        3'd2,
                                        3'd3,
                                        3'd4,
                                        3'd5,
                                        3'd6,
                                        3'd7
                                        };
						w_addr = count;
						w_en = 1'b1;
				end
				STATE_NORMAL: begin
						w_data = 	w_data_in;
						w_addr = 	w_addr_in;
						w_en   = 	w_en_in;
						
				end
			endcase
		end
	end	
	
	always @(posedge clk) begin

		if(w_en) begin
			mem[w_addr] <= w_data;
		end

		r_data_out_reg <= mem[r_addr_in];

	end		
	// assign 	r_data_out = mem[r_addr_in];
                            // ,
							// mem[{out_address,3'b001}],
							// mem[{out_address,3'b010}],
							// mem[{out_address,3'b011}],
							// mem[{out_address,3'b100}],
							// mem[{out_address,3'b101}],
							// mem[{out_address,3'b110}],
							// mem[{out_address,3'b111}]};
						
// synthesis translate_off
initial 
begin
	// $monitor("age %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d",mem[0],mem[1],mem[2],mem[3],mem[4],mem[5],mem[6],mem[7],mem[8],mem[9],mem[10],mem[11],mem[12],mem[13],mem[14],mem[15]);
end
// synthesis translate_on				
						
endmodule