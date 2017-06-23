`timescale 1ns / 1ps
module tag_memory_write_first
(
   clk,
   reset,
   r_addr_in,
   w_addr_in,
   r_data_out,
   w_data_in,
   w_en_in,
   //r_en_in,
   valid_bits_out

);

    `include "../sim/pred_def.v"
    `include "../sim/cache_configs_def.v"
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
   parameter												TAG_BANK_LEN = SET_ADDR_WDTH + C_N_WAY - C_LG_BANKS ;
    
   
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    localparam                          STATE_CLEAR				        = 0;    // the state that is entered upon reset
    localparam                          STATE_NORMAL	                = 1;
      
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    

   input                           	                clk;
   input									        reset;
   input	[TAG_ADDR_WDTH-1:0]      		        w_data_in;
   input	[SET_ADDR_WDTH - C_LG_BANKS -1:0]	    r_addr_in;			// read 8 tags at once 
   input	[TAG_BANK_LEN-1:0]				        w_addr_in;			// write 1 tag at once 3 LSBs for set_idx
   input										    w_en_in;
    //input                                         r_en_in;
   output  reg [(1<<C_N_WAY)*TAG_ADDR_WDTH-1:0]     r_data_out;
   output 	reg [(1<<C_N_WAY)-1:0]				    valid_bits_out;
   
   
   //---------------------------------------------------------------------------------------------------------------------
    // Internal wires and registers
    //---------------------------------------------------------------------------------------------------------------------
  

   reg   [TAG_ADDR_WDTH-1:0]      				    mem [(1<<TAG_BANK_LEN)-1:0];
   reg	[(1<<TAG_BANK_LEN)-1:0] 			        valid_bits;
   reg 	[SET_ADDR_WDTH - C_LG_BANKS -1:0]	        r_addr_d;			// read 8 tags at once 
   reg   [TAG_ADDR_WDTH-1:0]                        r_data_d[(1<<C_N_WAY)-1:0] ;
   reg [(1<<C_N_WAY)-1:0]						    valid_bits_d;
   //reg	[SET_ADDR_WDTH - Y_BANK_BITS-1:0]		out_address;
//	reg     [TAG_BANK_LEN-1:0]                      count;
//  reg                                             all_clear;
//	integer state;
   wire [(1<<C_N_WAY)-1:0]valid_bit_sets[0 : (1<<SET_ADDR_WDTH)-1];
  
       generate
         genvar ii;
         for(ii=0;ii<(1<<SET_ADDR_WDTH);ii=ii+1) begin
            assign valid_bit_sets[ii] = valid_bits[(ii+1)*(1<<C_N_WAY) -1: (ii)*(1<<C_N_WAY)];
         end
      endgenerate
    //---------------------------------------------------------------------------------------------------------------------
    // Implmentation
    //---------------------------------------------------------------------------------------------------------------------
    

    
   always @(posedge clk) begin
      if(reset) begin
         valid_bits <= {(1<<TAG_BANK_LEN){1'b0}};
      end
      else begin
         if(w_en_in) begin
            valid_bits[w_addr_in]	<= 1'b1;
         end
      end
   end	
   
   always@(posedge clk) begin
          if(w_en_in) begin
            mem[w_addr_in] <= w_data_in;
         end  
   end
   
   always@(posedge clk) begin
      r_addr_d <= r_addr_in;
   end
   
   // always@(posedge clk) begin
   
      // if(r_addr_in == w_addr_in[SET_ADDR_WDTH + C_N_WAY-1:C_N_WAY] && w_en_in) begin
         // case(w_addr_in[C_N_WAY-1:0])
            // 3'd0: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,mem[{r_addr_in,3'b110}],mem[{r_addr_in,3'b101}],mem[{r_addr_in,3'b100}],mem[{r_addr_in,3'b011}],mem[{r_addr_in,3'b010}],mem[{r_addr_in,3'b001}],w_data_in				};		end					
            // 3'd1: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,mem[{r_addr_in,3'b110}],mem[{r_addr_in,3'b101}],mem[{r_addr_in,3'b100}],mem[{r_addr_in,3'b011}],mem[{r_addr_in,3'b010}],w_data_in				,mem[{r_addr_in,3'b000}]};		end					
            // 3'd2: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,mem[{r_addr_in,3'b110}],mem[{r_addr_in,3'b101}],mem[{r_addr_in,3'b100}],mem[{r_addr_in,3'b011}],w_data_in				,mem[{r_addr_in,3'b001}],mem[{r_addr_in,3'b000}]};		end					
            // 3'd3: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,mem[{r_addr_in,3'b110}],mem[{r_addr_in,3'b101}],mem[{r_addr_in,3'b100}],w_data_in				,mem[{r_addr_in,3'b010}],mem[{r_addr_in,3'b001}],mem[{r_addr_in,3'b000}]};		end					
            // 3'd4: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,mem[{r_addr_in,3'b110}],mem[{r_addr_in,3'b101}],w_data_in				,mem[{r_addr_in,3'b011}],mem[{r_addr_in,3'b010}],mem[{r_addr_in,3'b001}],mem[{r_addr_in,3'b000}]};		end					
            // 3'd5: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,mem[{r_addr_in,3'b110}],w_data_in				,mem[{r_addr_in,3'b100}],mem[{r_addr_in,3'b011}],mem[{r_addr_in,3'b010}],mem[{r_addr_in,3'b001}],mem[{r_addr_in,3'b000}]};		end					
            // 3'd6: begin r_data_out <=  {	mem[{r_addr_in,3'b111}]	,w_data_in				,mem[{r_addr_in,3'b101}],mem[{r_addr_in,3'b100}],mem[{r_addr_in,3'b011}],mem[{r_addr_in,3'b010}],mem[{r_addr_in,3'b001}],mem[{r_addr_in,3'b000}]};		end					
            // 3'd7: begin r_data_out <=  {	w_data_in				,mem[{r_addr_in,3'b110}],mem[{r_addr_in,3'b101}],mem[{r_addr_in,3'b100}],mem[{r_addr_in,3'b011}],mem[{r_addr_in,3'b010}],mem[{r_addr_in,3'b001}],mem[{r_addr_in,3'b000}]};		end					
         // endcase
      // end
      // else begin
             // r_data_out <=  {	mem[{r_addr_in,3'b111}],
                              // mem[{r_addr_in,3'b110}],
                              // mem[{r_addr_in,3'b101}],
                              // mem[{r_addr_in,3'b100}],
                              // mem[{r_addr_in,3'b011}],
                              // mem[{r_addr_in,3'b010}],
                              // mem[{r_addr_in,3'b001}],
                              // mem[{r_addr_in,3'b000}]};     
      // end
   // end
   
   always@(*) begin
   
      if(r_addr_d == w_addr_in[SET_ADDR_WDTH + C_N_WAY-1:C_N_WAY] && w_en_in) begin
         case(w_addr_in[C_N_WAY-1:0])
            3'd0: begin r_data_out =  {	r_data_d[3'b111] ,r_data_d[3'b110],r_data_d[3'b101],r_data_d[3'b100],r_data_d[3'b011],r_data_d[3'b010],r_data_d[3'b001],w_data_in		 };		end					
            3'd1: begin r_data_out =  {	r_data_d[3'b111] ,r_data_d[3'b110],r_data_d[3'b101],r_data_d[3'b100],r_data_d[3'b011],r_data_d[3'b010],w_data_in		  ,r_data_d[3'b000]};		end					
            3'd2: begin r_data_out =  {	r_data_d[3'b111] ,r_data_d[3'b110],r_data_d[3'b101],r_data_d[3'b100],r_data_d[3'b011],w_data_in	      ,r_data_d[3'b001],r_data_d[3'b000]};		end					
            3'd3: begin r_data_out =  {	r_data_d[3'b111] ,r_data_d[3'b110],r_data_d[3'b101],r_data_d[3'b100],w_data_in		 ,r_data_d[3'b010],r_data_d[3'b001],r_data_d[3'b000]};		end					
            3'd4: begin r_data_out =  {	r_data_d[3'b111] ,r_data_d[3'b110],r_data_d[3'b101],w_data_in	     ,r_data_d[3'b011],r_data_d[3'b010],r_data_d[3'b001],r_data_d[3'b000]};		end					
            3'd5: begin r_data_out =  {	r_data_d[3'b111] ,r_data_d[3'b110],w_data_in	      ,r_data_d[3'b100],r_data_d[3'b011],r_data_d[3'b010],r_data_d[3'b001],r_data_d[3'b000]};		end					
            3'd6: begin r_data_out =  {	r_data_d[3'b111] ,w_data_in	    ,r_data_d[3'b101],r_data_d[3'b100],r_data_d[3'b011],r_data_d[3'b010],r_data_d[3'b001],r_data_d[3'b000]};		end					
            3'd7: begin r_data_out =  {	w_data_in		  ,r_data_d[3'b110],r_data_d[3'b101],r_data_d[3'b100],r_data_d[3'b011],r_data_d[3'b010],r_data_d[3'b001],r_data_d[3'b000]};		end					
         endcase
      end
      else begin
             r_data_out =  {  r_data_d[3'b111],
                              r_data_d[3'b110],
                              r_data_d[3'b101],
                              r_data_d[3'b100],
                              r_data_d[3'b011],
                              r_data_d[3'b010],
                              r_data_d[3'b001],
                              r_data_d[3'b000]};     
      end
   end
   
   reg [C_N_WAY:0]  i;
   always@(posedge clk) begin
      for (i=0; i < (1<<C_N_WAY); i=i+1) begin
         if((r_addr_in == w_addr_in[SET_ADDR_WDTH + C_N_WAY-1:C_N_WAY] && w_en_in) )begin
            if(w_addr_in[C_N_WAY-1:0] == i) begin
               r_data_d[i] <=       w_data_in;
            end
            else begin
               r_data_d[i]      <= 	     mem[{r_addr_in,i[C_N_WAY-1:0]}];
            end
         end
         else begin
            r_data_d[i]      <= 	     mem[{r_addr_in,i[C_N_WAY-1:0]}];       
         end
      end
   end  
         
   
   always@(posedge clk) begin
         if(r_addr_in == w_addr_in[SET_ADDR_WDTH + C_N_WAY-1:C_N_WAY] && w_en_in) begin
            case(w_addr_in[C_N_WAY-1:0])
               3'd0: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,valid_bits[{r_addr_in,3'b110}]	,valid_bits[{r_addr_in,3'b101}]	,valid_bits[{r_addr_in,3'b100}]	,valid_bits[{r_addr_in,3'b011}]	,valid_bits[{r_addr_in,3'b010}]	,valid_bits[{r_addr_in,3'b001}]	,1'b1          					};		end					
               3'd1: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,valid_bits[{r_addr_in,3'b110}]	,valid_bits[{r_addr_in,3'b101}]	,valid_bits[{r_addr_in,3'b100}]	,valid_bits[{r_addr_in,3'b011}]	,valid_bits[{r_addr_in,3'b010}]	,1'b1          					,valid_bits[{r_addr_in,3'b000}]};		end					
               3'd2: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,valid_bits[{r_addr_in,3'b110}]	,valid_bits[{r_addr_in,3'b101}]	,valid_bits[{r_addr_in,3'b100}]	,valid_bits[{r_addr_in,3'b011}]	,1'b1          					,valid_bits[{r_addr_in,3'b001}]	,valid_bits[{r_addr_in,3'b000}]};		end					
               3'd3: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,valid_bits[{r_addr_in,3'b110}]	,valid_bits[{r_addr_in,3'b101}]	,valid_bits[{r_addr_in,3'b100}]	,1'b1          					,valid_bits[{r_addr_in,3'b010}]	,valid_bits[{r_addr_in,3'b001}]	,valid_bits[{r_addr_in,3'b000}]};		end					
               3'd4: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,valid_bits[{r_addr_in,3'b110}]	,valid_bits[{r_addr_in,3'b101}]	,1'b1          					,valid_bits[{r_addr_in,3'b011}]	,valid_bits[{r_addr_in,3'b010}]	,valid_bits[{r_addr_in,3'b001}]	,valid_bits[{r_addr_in,3'b000}]};		end					
               3'd5: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,valid_bits[{r_addr_in,3'b110}]	,1'b1          					,valid_bits[{r_addr_in,3'b100}]	,valid_bits[{r_addr_in,3'b011}]	,valid_bits[{r_addr_in,3'b010}]	,valid_bits[{r_addr_in,3'b001}]	,valid_bits[{r_addr_in,3'b000}]};		end					
               3'd6: begin valid_bits_d <=  {	valid_bits[{r_addr_in,3'b111}]	,1'b1          					,valid_bits[{r_addr_in,3'b101}]	,valid_bits[{r_addr_in,3'b100}]	,valid_bits[{r_addr_in,3'b011}]	,valid_bits[{r_addr_in,3'b010}]	,valid_bits[{r_addr_in,3'b001}]	,valid_bits[{r_addr_in,3'b000}]};		end					
               3'd7: begin valid_bits_d <=  {	1'b1          					,valid_bits[{r_addr_in,3'b110}]	,valid_bits[{r_addr_in,3'b101}]	,valid_bits[{r_addr_in,3'b100}]	,valid_bits[{r_addr_in,3'b011}]	,valid_bits[{r_addr_in,3'b010}]	,valid_bits[{r_addr_in,3'b001}]	,valid_bits[{r_addr_in,3'b000}]};		end					
            endcase
         end
         else begin
            valid_bits_d <=  {	valid_bit_sets[{r_addr_in}]};	
         end
   end
   
    
   always@(*) begin
         if(r_addr_d == w_addr_in[SET_ADDR_WDTH + C_N_WAY-1:C_N_WAY] && w_en_in) begin
            case(w_addr_in[C_N_WAY-1:0])
               3'd0: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,valid_bits_d[{3'b110}]	,valid_bits_d[{3'b101}]	,valid_bits_d[{3'b100}]	,valid_bits_d[{3'b011}]	,valid_bits_d[{3'b010}]	,valid_bits_d[{3'b001}]	,1'b1          					};		end					
               3'd1: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,valid_bits_d[{3'b110}]	,valid_bits_d[{3'b101}]	,valid_bits_d[{3'b100}]	,valid_bits_d[{3'b011}]	,valid_bits_d[{3'b010}]	,1'b1          		   ,valid_bits_d[{3'b000}]};		end					
               3'd2: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,valid_bits_d[{3'b110}]	,valid_bits_d[{3'b101}]	,valid_bits_d[{3'b100}]	,valid_bits_d[{3'b011}]	,1'b1          	      ,valid_bits_d[{3'b001}]	,valid_bits_d[{3'b000}]};		end					
               3'd3: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,valid_bits_d[{3'b110}]	,valid_bits_d[{3'b101}]	,valid_bits_d[{3'b100}]	,1'b1          		   ,valid_bits_d[{3'b010}]	,valid_bits_d[{3'b001}]	,valid_bits_d[{3'b000}]};		end					
               3'd4: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,valid_bits_d[{3'b110}]	,valid_bits_d[{3'b101}]	,1'b1          		   ,valid_bits_d[{3'b011}]	,valid_bits_d[{3'b010}]	,valid_bits_d[{3'b001}]	,valid_bits_d[{3'b000}]};		end					
               3'd5: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,valid_bits_d[{3'b110}]	,1'b1          		   ,valid_bits_d[{3'b100}]	,valid_bits_d[{3'b011}]	,valid_bits_d[{3'b010}]	,valid_bits_d[{3'b001}]	,valid_bits_d[{3'b000}]};		end					
               3'd6: begin valid_bits_out =  {	valid_bits_d[{3'b111}]	,1'b1          		   ,valid_bits_d[{3'b101}]	,valid_bits_d[{3'b100}]	,valid_bits_d[{3'b011}]	,valid_bits_d[{3'b010}]	,valid_bits_d[{3'b001}]	,valid_bits_d[{3'b000}]};		end					
               3'd7: begin valid_bits_out =  {	1'b1          				,valid_bits_d[{3'b110}]	,valid_bits_d[{3'b101}]	,valid_bits_d[{3'b100}]	,valid_bits_d[{3'b011}]	,valid_bits_d[{3'b010}]	,valid_bits_d[{3'b001}]	,valid_bits_d[{3'b000}]};		end					
            endcase
         end
         else begin
            valid_bits_out =  {valid_bits_d};	
         end
   end              
   
endmodule
