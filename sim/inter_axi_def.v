
`define AX_SIZE_1        3'b000 
`define AX_SIZE_2        3'b001 
`define AX_SIZE_4        3'b010 
`define AX_SIZE_8        3'b011 
`define AX_SIZE_16       3'b100 
`define AX_SIZE_32       3'b101 
`define AX_SIZE_64       3'b110 
`define AX_SIZE_128      3'b111 

`define AX_LEN_1     8'b0000_0000 
`define AX_LEN_2     8'b0000_0001 
`define AX_LEN_3     8'b0000_0010 
`define AX_LEN_4     8'b0000_0011 
`define AX_LEN_5     8'b0000_0100 
`define AX_LEN_6     8'b0000_0101 
`define AX_LEN_7     8'b0000_0110 
`define AX_LEN_8     8'b0000_0111 
`define AX_LEN_9     8'b0000_1000 
`define AX_LEN_10    8'b0000_1001 
`define AX_LEN_11    8'b0000_1010 
`define AX_LEN_12    8'b0000_1011 
`define AX_LEN_13    8'b0000_1100 
`define AX_LEN_14    8'b0000_1101 
`define AX_LEN_15    8'b0000_1110 
`define AX_LEN_16    8'b0000_1111 
`define AX_LEN_96    8'd95 
`define AX_LEN_128    8'd127

`define AX_BURST_INC       2'b01
`define AX_LOCK_DEFAULT    1'b0
`define AX_CACHE_DEFAULT    4'b0000

`define AX_PROT_DATA    3'b000



parameter MV_FIELD_AXI_DATA_WIDTH  = 80;

`define XRESP_DEC_ERROR 2'b11
`define XRESP_SLAV_ERROR 2'b10

parameter AXI_ADDR_WDTH = 32;
parameter AXI_CACHE_DATA_WDTH = 512;
parameter AXI_MIG_DATA_WIDTH = 512;

`ifdef BIT_DEPTH_12
   `ifdef DEF_CH_TYPE_422
      `define REF_PIX_BU_OFFSET (9'd96)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd7)
      `define REF_PIX_BU_ROW_OFFSET (12'd768)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd10)
      `define REF_PIX_IU_OFFSET (16'd12288)
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd14)

      `define REF_PIX_IU_ROW_OFFSET (22'd380928)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd20)
      `define REF_PIX_FRAME_OFFSET (29'h02400000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h024)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h0D80_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)
   `elsif DEF_CH_TYPE_444
      `define REF_PIX_BU_OFFSET (10'd96)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd7)
      `define REF_PIX_BU_ROW_OFFSET (13'd768)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd10)
      `define REF_PIX_IU_OFFSET (16'd18432)
      // `define REF_PIX_IU_OFFSET_SHIFT (5'd15)

      `define REF_PIX_IU_ROW_OFFSET (23'd571392)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd21)
      `define REF_PIX_FRAME_OFFSET (29'h04800000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h048)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h1B00_0000)  
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)    
   `else 
   // DEF_CH_TYPE_420
      `define REF_PIX_BU_OFFSET (9'd96)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd7)
      `define REF_PIX_BU_ROW_OFFSET (12'd768)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd10)
      `define REF_PIX_IU_OFFSET (16'd9216)
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd14)

      `define REF_PIX_IU_ROW_OFFSET (22'd285696)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd20)
      `define REF_PIX_FRAME_OFFSET (29'h02400000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h024)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h0D80_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)   
   `endif

`elsif BIT_DEPTH_10
   `ifdef DEF_CH_TYPE_422
      `define REF_PIX_BU_OFFSET (9'd80)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd7)
      `define REF_PIX_BU_ROW_OFFSET (12'd640)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd10)
      `define REF_PIX_IU_OFFSET (16'd10240)
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd14)

      `define REF_PIX_IU_ROW_OFFSET (22'd317440)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd20)
      `define REF_PIX_FRAME_OFFSET (29'h02400000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h024)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h0D80_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16) 
   `elsif DEF_CH_TYPE_444
      `define REF_PIX_BU_OFFSET (9'd80)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd7)
      `define REF_PIX_BU_ROW_OFFSET (12'd640)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd10)
      `define REF_PIX_IU_OFFSET (16'd15360)
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd14)

      `define REF_PIX_IU_ROW_OFFSET (22'd476160)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd20)
      `define REF_PIX_FRAME_OFFSET (29'h02400000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h024)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h0D80_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)    
   `else 
   // DEF_CH_TYPE_420
      `define REF_PIX_BU_OFFSET (9'd80)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd7)
      `define REF_PIX_BU_ROW_OFFSET (12'd640)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd10)
      `define REF_PIX_IU_OFFSET (15'd7680)
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd13)

      `define REF_PIX_IU_ROW_OFFSET (20'd238080)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd19)
      `define REF_PIX_FRAME_OFFSET (29'h01200000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h012)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h07E0_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)   
   `endif

`else
// BIT_DEPTH_8
   `ifdef DEF_CH_TYPE_422
      `define REF_PIX_BU_OFFSET (9'd64)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd6)
      `define REF_PIX_BU_ROW_OFFSET (12'd512)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd9)
      `define REF_PIX_IU_OFFSET (15'd8192)
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd13)

      `define REF_PIX_IU_ROW_OFFSET (20'd253952)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd19)
      `define REF_PIX_FRAME_OFFSET (29'h01200000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h012)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h07E0_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16) 
   `elsif DEF_CH_TYPE_444
      `define REF_PIX_BU_OFFSET (9'd64)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd6)
      `define REF_PIX_BU_ROW_OFFSET (12'd512)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd9)
      `define REF_PIX_IU_OFFSET (16'd12288)  
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd14)

      `define REF_PIX_IU_ROW_OFFSET (22'd380928)
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd20)
      `define REF_PIX_FRAME_OFFSET (29'h02400000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h024)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h07E0_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)    
   `else 
   // DEF_CH_TYPE_420
      `define REF_PIX_BU_OFFSET (9'd64)
      // `define REF_PIX_BU_OFFSET_SHIFT (4'd6)
      `define REF_PIX_BU_ROW_OFFSET (12'd512)
      // `define REF_PIX_BU_ROW_OFFSET_SHIFT (4'd9)
      `define REF_PIX_IU_OFFSET (15'd6144)   
      // `define REF_PIX_IU_OFFSET_SHIFT (4'd13)

      `define REF_PIX_IU_ROW_OFFSET (20'd190464) // This number is assuming HD picture width
      // `define REF_PIX_IU_ROW_OFFSET_SHIFT (5'd19)
      `define REF_PIX_FRAME_OFFSET (29'h01200000)
      `define REF_PIX_FRAME_OFFSET_VAL (11'h012)
      `define REF_PIX_FRAME_OFFSET_SHIFT (8'd20)

      `define COL_MV_ADDR_OFFSET (32'h07E0_0000) 
      `define COL_MV_CTU_ROW_OFFSET (16'd16384)
      `define COL_MV_CTU_OFFSET (9'd256)
      `define COL_MV_INNER_CTU_ROW_OFFSET (7'd64)
      `define CTUS_PER_ROW (8'64)
      `define CTUS_PER_COL (8'36)
      `define COL_MV_FRAME_OFFSET (28'h90000)
      `define COL_MV_FRAME_OFFSET_VAL (10'h009)
      `define COL_MV_FRAME_OFFSET_SHIFT (8'd16)   
   `endif   
`endif