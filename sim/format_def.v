`define BIT_DEPTH_8
// `define BIT_DEPTH_10
// `define BIT_DEPTH_12
`define DEF_CH_TYPE_420
// `define DEF_CH_TYPE_422
// `define DEF_CH_TYPE_444

`define CH_FORMAT_420 8'h20
`define CH_FORMAT_422 8'h22
`define CH_FORMAT_444 8'h44

`ifdef DEF_CH_TYPE_444
   parameter                          C_SUB_WIDTH  = 1;
   parameter                          C_SUB_HEIGHT = 1;
   parameter                          CH_FORMAT_IDC = `CH_FORMAT_444;
   parameter                          CHROMA_ARRAY_TYPE = 3;
`elsif DEF_CH_TYPE_422
   parameter                          C_SUB_WIDTH  = 2;
   parameter                          C_SUB_HEIGHT = 1;
   parameter                          CH_FORMAT_IDC = `CH_FORMAT_422;
   parameter                          CHROMA_ARRAY_TYPE = 2;
`else     
   parameter                          C_SUB_WIDTH  = 2;
   parameter                          C_SUB_HEIGHT = 2;
   parameter                          CH_FORMAT_IDC = `CH_FORMAT_420;
   parameter                          CHROMA_ARRAY_TYPE = 1;
`endif

    
`ifdef BIT_DEPTH_8
     parameter  PIXEL_WIDTH                  = 8;
    
`elsif BIT_DEPTH_10
     parameter  PIXEL_WIDTH                  = 10;
`elsif BIT_DEPTH_12     
     parameter  PIXEL_WIDTH                  = 12;
`else
    //parameter  PIXEL_WIDTH                 = 8;
    //localparam  BIT_DEPTH                   = PIXEL_WIDTH;
`endif
// localparam  LUMA_BITS = PIXEL_WIDTH;
localparam  CHMA_BITS = PIXEL_WIDTH;
localparam  BIT_DEPTH                   = PIXEL_WIDTH;