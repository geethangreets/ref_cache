module compare_tags_new
(
    tags_set_in,
	the_tag_in,
	ishit,
	valid_bits_in,
	set_idx

);
    `include "../sim/pred_def.v"
    `include "../sim/cache_configs_def.v"
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    

    
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    

    
    
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------

	input	[TAG_ADDR_WDTH-1:0]					the_tag_in;		
	input	[(1<<C_N_WAY)-1:0]					valid_bits_in;
	output										ishit;
	output	reg [C_N_WAY-1:0]					set_idx;
	input	[(1<<C_N_WAY)*TAG_ADDR_WDTH-1:0]    tags_set_in;
	
	
    //---------------------------------------------------------------------------------------------------------------------
    // Internal wires and registers
    //---------------------------------------------------------------------------------------------------------------------
    
	reg [C_N_WAY:0] i;
	reg [(1<<C_N_WAY)-1:0] ishit_m;
	wire [TAG_ADDR_WDTH-1:0] tags_m[(1<<C_N_WAY)-1:0];
	
	
   assign tags_m[0] = tags_set_in[(TAG_ADDR_WDTH)*1-1:(TAG_ADDR_WDTH)*0];
	assign tags_m[1] = tags_set_in[(TAG_ADDR_WDTH)*2-1:(TAG_ADDR_WDTH)*1];
	assign tags_m[2] = tags_set_in[(TAG_ADDR_WDTH)*3-1:(TAG_ADDR_WDTH)*2];
	assign tags_m[3] = tags_set_in[(TAG_ADDR_WDTH)*4-1:(TAG_ADDR_WDTH)*3];
	assign tags_m[4] = tags_set_in[(TAG_ADDR_WDTH)*5-1:(TAG_ADDR_WDTH)*4];
	assign tags_m[5] = tags_set_in[(TAG_ADDR_WDTH)*6-1:(TAG_ADDR_WDTH)*5];
	assign tags_m[6] = tags_set_in[(TAG_ADDR_WDTH)*7-1:(TAG_ADDR_WDTH)*6];
	assign tags_m[7] = tags_set_in[(TAG_ADDR_WDTH)*8-1:(TAG_ADDR_WDTH)*7];
	
    
	always@(*) begin
		for(i=0;i<(1<<C_N_WAY);i=i+1) begin
			if(valid_bits_in[i] == 1) begin
				if(the_tag_in == tags_m[i]) begin
					ishit_m[i] = 1;
				end
				else begin
					ishit_m[i] = 0;
				end			
			end
			else begin
				ishit_m[i] = 0;
			end
		end
	end
    
	always@(*) begin
		
		if		(ishit_m[0]) begin set_idx = 3'd0; end
		else if	(ishit_m[1]) begin set_idx = 3'd1; end
		else if	(ishit_m[2]) begin set_idx = 3'd2; end
		else if	(ishit_m[3]) begin set_idx = 3'd3; end
		else if	(ishit_m[4]) begin set_idx = 3'd4; end
		else if	(ishit_m[5]) begin set_idx = 3'd5; end
		else if	(ishit_m[6]) begin set_idx = 3'd6; end
		else if	(ishit_m[7]) begin set_idx = 3'd7; end
		else begin
			set_idx = 3'd7;
		end
	end
	assign ishit = ((ishit_m[0] || ishit_m[1]) || (ishit_m[2] || ishit_m[3])) || ((ishit_m[4] || ishit_m[5]) || (ishit_m[6] || ishit_m[7]));
	
	endmodule