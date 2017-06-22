`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   10:02:10 04/08/2014
// Design Name:   add
// Module Name:   E:/Uni/Semester 5/DSD/FPGA projects/adder/te45.v
// Project Name:  adder
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: add
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module mem_slave_top_module(

	clk,
	reset,
    arid,
    araddr,
    arlen,
    arsize,
    arburst,
    arlock,
    arcache,
    arprot,
    arvalid,
    arready,
    rid,
    rdata,
    rresp,
    rlast,
    rvalid,
    rready,
    awid,
    awaddr,
    awlen,
    awsize,
    awburst,
    awlock,
    awcache,
    awprot,
    awvalid,
    awready,
    wid,
    wdata,
    wstrb,
    wvalid,
    wlast,
    wready,
    bid,
    bresp,
    bvalid,
    bready
 );

//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
 `include "../sim/param.v" ;
	parameter DUMMY_MEM = 0;
  parameter READ_DATA_DEBUG = 0;
  parameter WRITE_DATA_DEBUG = 0;
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------

    input [ADD_ID_WIDTH-1:0]arid;
    input [ADD_WIDTH-1:0]araddr;
    input [BURST_LEN-1:0]arlen;
    input [BURST_SIZE-1:0]arsize;
    input [BURST_TYPE-1:0]arburst;
    input [1:0]arlock;
    input [3:0]arcache;
    input [2:0]arprot;
    input  arvalid;
    output arready;

    output[ADD_ID_WIDTH-1:0]rid;
    output[DATA_WIDTH-1:0]rdata;
    output[1:0]rresp;
    output rlast;
    output rvalid;
    input rready;

    input [ADD_ID_WIDTH-1:0]awid;
    input [ADD_WIDTH-1:0]awaddr;
    input [BURST_LEN-1:0]awlen;
    input [BURST_SIZE-1:0]awsize;
    input [BURST_TYPE-1:0]awburst;
    input [1:0]awlock;
    input [3:0]awcache;
    input [2:0]awprot;
    input  awvalid;
    output awready;

    input [ADD_ID_WIDTH-1:0]wid;
    input [DATA_WIDTH-1:0]wdata;
    input [(DATA_WIDTH>>3)-1:0]wstrb;
    input wlast;
    input wvalid;
    output wready;

    output [ADD_ID_WIDTH-1:0]bid;
    output [1:0] bresp;
    output bvalid;
    input bready;


	input clk;
	input reset;

   //Sub Module IO swires
    wire [ADD_WIDTH-1:0] inter_read_address;
    wire inter_read_ready;
    wire inter_read_valid;
    wire [ADD_ID_WIDTH-1:0]inter_read_id;
    wire [BURST_LEN-1:0]inter_read_length;
    wire [BURST_SIZE-1:0]inter_read_size;
    wire [BURST_TYPE-1:0]inter_read_burst;

    wire [ADD_WIDTH-1:0] inter_write_address;
    wire inter_write_ready;
    wire inter_write_valid;
    wire inter_write_resp_ready;
    wire inter_write_resp_valid;
    wire [ADD_ID_WIDTH-1:0]inter_write_id;
    wire [BURST_LEN-1:0]inter_write_length;
    wire [BURST_SIZE-1:0]inter_write_size;
    wire [BURST_TYPE-1:0]inter_write_burst;
    wire [1:0] inter_resp;
    wire [ADD_ID_WIDTH-1:0]inter_write_resp_id;
    //wire enable;
    //wire rw_b;
    //wire [ADDRESS_WIDTH -1:0]address ;
    //wire [REGISTER_SIZE-1:0] data_in ;
    //wire [REGISTER_SIZE-1:0] data_out ;



// Instantiate the Unit Under Test (UUT)
    add_read a_read (
      .clk(clk),
      .reset(reset),
      .arid(arid),
      .araddr(araddr),
      .arlen(arlen),
      .arsize(arsize),
      .arburst(arburst),
      .arlock(arlock),
      .arcache(arcache),
      .arprot(arprot),
      .arvalid(arvalid),
      .arready(arready),
      .address_out(inter_read_address),
      .mod2_ready_in(inter_read_ready),
      .mod2_valid_out(inter_read_valid),
      .id_out(inter_read_id),
      .len_out(inter_read_length),
      .size_out(inter_read_size),
      .burst_out(inter_read_burst)
    );

    add_write a_write (
      .clk(clk),
      .reset(reset),
      .awid(awid),
      .awaddr(awaddr),
      .awlen(awlen),
      .awsize(awsize),
      .awburst(awburst),
      .awlock(awlock),
      .awcache(awcache),
      .awprot(awprot),
      .awvalid(awvalid),
      .awready(awready),
      .address_out(inter_write_address),
      .mod2_ready_in(inter_write_ready),
      .mod2_valid_out(inter_write_valid),
      .id_out(inter_write_id),
      .len_out(inter_write_length),
      .size_out(inter_write_size),
      .burst_out(inter_write_burst)
    );

    data_read_write
	#(
      .DUMMY_MEM(DUMMY_MEM),
      .READ_DATA_DEBUG(READ_DATA_DEBUG),
      .WRITE_DATA_DEBUG(WRITE_DATA_DEBUG)
    )
	data_wr_rd_block (

      .clk(clk),
      .reset(reset),

      .rid(rid),
      .rdata(rdata),
      .rresp(rresp),
      .rlast(rlast),
      .rvalid(rvalid),
      .rready(rready),
      .raddr_in(inter_read_address),
      .rlen_in(inter_read_length),
      .rsize_in(inter_read_size),
      .rburst_in(inter_read_burst),
      .rid_in(inter_read_id),
      .read_mod1_ready_out(inter_read_ready),
      .read_mod1_valid_in(inter_read_valid),

      .awid(awid),
      .wid(wid),
      .wdata(wdata),
      .wstrb(wstrb),
      .wlast(wlast),
      .wvalid(wvalid),
      .wready(wready),

      .write_mod1_valid_in(inter_write_valid),
      .write_mod1_ready_out(inter_write_ready),
      .mod3_ready_in(inter_write_resp_ready),
      .mod3_valid_out(inter_write_resp_valid),

      .addr_in(inter_write_address),
      .id_in(inter_write_id),
      .write_burst_length_in(inter_write_length),
      .write_burst_size_in(inter_write_size),
      .write_burst_type_in(inter_write_burst),
      .id_out(inter_write_resp_id),
      .resp_out(inter_resp)
      );

    data_resp data_resp (
      .clk(clk),
      .reset(reset),
      .bid(bid),
      .bresp(bresp),
      .bvalid(bvalid),
      .bready(bready),
      .id_in(inter_write_resp_id),
      .resp_in(inter_resp),
      .mod2_valid_in(inter_write_resp_valid),
      .mod2_ready_out(inter_write_resp_ready)
      );



endmodule
