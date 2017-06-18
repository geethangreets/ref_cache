`timescale 1ns / 1ps
module new_age_converter
(
    ishit_in,
	set_idx_in,
	age_vals_in,
	new_age_vals_out,
    set_idx_miss_bnk_out

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
    input [(1<<C_N_WAY)*C_N_WAY-1:0]				age_vals_in;
	output[(1<<C_N_WAY)*C_N_WAY-1:0]				new_age_vals_out;
    output reg[C_N_WAY-1:0]                         set_idx_miss_bnk_out;
	input											ishit_in;
	input [C_N_WAY-1:0]                             set_idx_in;									

    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal wires and registers
    //---------------------------------------------------------------------------------------------------------------------
    
    wire [C_N_WAY-1:0] old_age_val [(1<<C_N_WAY)-1:0];
    reg  [C_N_WAY-1:0] new_age_val_m [(1<<C_N_WAY)-1:0];
    //---------------------------------------------------------------------------------------------------------------------
    // Implmentation
    //---------------------------------------------------------------------------------------------------------------------
    
    assign old_age_val[0] = age_vals_in[C_N_WAY*1-1:C_N_WAY*0];
    assign old_age_val[1] = age_vals_in[C_N_WAY*2-1:C_N_WAY*1];
    assign old_age_val[2] = age_vals_in[C_N_WAY*3-1:C_N_WAY*2];
    assign old_age_val[3] = age_vals_in[C_N_WAY*4-1:C_N_WAY*3];
    assign old_age_val[4] = age_vals_in[C_N_WAY*5-1:C_N_WAY*4];
    assign old_age_val[5] = age_vals_in[C_N_WAY*6-1:C_N_WAY*5];
    assign old_age_val[6] = age_vals_in[C_N_WAY*7-1:C_N_WAY*6];
    assign old_age_val[7] = age_vals_in[C_N_WAY*8-1:C_N_WAY*7];
   
    assign new_age_vals_out[C_N_WAY*1-1:C_N_WAY*0] = new_age_val_m[0];
    assign new_age_vals_out[C_N_WAY*2-1:C_N_WAY*1] = new_age_val_m[1];
    assign new_age_vals_out[C_N_WAY*3-1:C_N_WAY*2] = new_age_val_m[2];
    assign new_age_vals_out[C_N_WAY*4-1:C_N_WAY*3] = new_age_val_m[3];
    assign new_age_vals_out[C_N_WAY*5-1:C_N_WAY*4] = new_age_val_m[4];
    assign new_age_vals_out[C_N_WAY*6-1:C_N_WAY*5] = new_age_val_m[5];
    assign new_age_vals_out[C_N_WAY*7-1:C_N_WAY*6] = new_age_val_m[6];
    assign new_age_vals_out[C_N_WAY*8-1:C_N_WAY*7] = new_age_val_m[7];   
    
    integer i;
    
    always@(*) begin
        
        if(ishit_in) begin
            for( i=0;i<(1<<C_N_WAY);i=i+1) begin
                if( i == set_idx_in) begin
                    new_age_val_m[i] = 0;
                end
                else if(old_age_val[i] < old_age_val[set_idx_in]) begin     // for age values below current hit age, increment by 1
                    new_age_val_m[i] = (old_age_val[i] + 1)%(1<<C_N_WAY);
                end
                else  begin
                    new_age_val_m[i] = old_age_val[i];
                end
            end            
        end
        else begin              // if miss
            for( i=0;i<=(1<<C_N_WAY)-1;i=i+1) begin
                if(old_age_val[i] == {C_N_WAY{1'b1}}) begin     // if oldest age location found
                    new_age_val_m[i] = 0;
                end
                else begin
                    new_age_val_m[i] = (old_age_val[i] + 1)%(1<<C_N_WAY);
                end
            end          
        end
    end
    
	always@(*) begin
		set_idx_miss_bnk_out = set_idx_in;
		     if(old_age_val[0] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd0; end
		else if(old_age_val[1] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd1; end
		else if(old_age_val[2] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd2; end
		else if(old_age_val[3] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd3; end
		else if(old_age_val[4] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd4; end
		else if(old_age_val[5] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd5; end
		else if(old_age_val[6] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd6; end
		else if(old_age_val[7] == {C_N_WAY{1'b1}}) begin set_idx_miss_bnk_out = 3'd7; end
			
	end
 
endmodule