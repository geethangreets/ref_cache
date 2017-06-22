  // `define WRITE_DATA_DEBUG
  // `define TEST_DEBUG
  parameter ADD_ID_WIDTH = 4;
  parameter ADD_WIDTH = 32;
  parameter BURST_LEN = 8;
  parameter BURST_SIZE = 3;
  parameter DATA_WIDTH = 1024;

    //memory module parameters
  //parameter   REGISTER_SIZE=8;
  //parameter   NO_OF_REGISTERS=256 ;    //total Memory size = REGISTER_SIZE*NO_OF_REGISTERS
  //parameter   ADDRESS_WIDTH=8;
//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------
  localparam BURST_TYPE = 2;


  parameter MAX_BYTE_SIZE = 128;
  parameter MAX_BIT_SIZE = 1024;
