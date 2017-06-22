`timescale 1ns / 1ps
`define TEST_DEBUG
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   17:39:54 04/10/2014
// Design Name:   top_module
// Module Name:   E:/Uni/Semester 5/DSD/FPGA projects/hjsh/ter.v
// Project Name:  hjsh
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: top_module
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module top_test;
	`include"param.v"
    `include "axi_def.v"
	reg clk;
    reg reset;

    reg [ADD_ID_WIDTH-1:0]arid;
    reg [ADD_WIDTH-1:0]araddr;
    reg [BURST_LEN-1:0]arlen;
    reg [BURST_SIZE-1:0]arsize;
    reg [BURST_TYPE-1:0]arburst;
    reg [1:0]arlock;
    reg [3:0]arcache;
    reg [2:0]arprot;
    reg  arvalid;
    wire arready;

    wire [ADD_ID_WIDTH-1:0]rid;
    wire [DATA_WIDTH-1:0]rdata;
    wire [1:0]rresp;
    wire rlast;
    wire rvalid;
    reg rready;

    reg [ADD_ID_WIDTH-1:0]awid;
    reg [ADD_WIDTH-1:0]awaddr;
    reg [BURST_LEN-1:0]awlen;
    reg [BURST_SIZE-1:0]awsize;
    reg [BURST_TYPE-1:0]awburst;
    reg [1:0]awlock;
    reg [3:0]awcache;
    reg [2:0]awprot;
    reg  awvalid;
    wire awready;

    reg [ADD_ID_WIDTH-1:0]wid;
    reg [DATA_WIDTH-1:0]wdata;
    reg [(DATA_WIDTH>>3)-1:0]wstrb;
    reg wlast;
    reg wvalid;
    wire wready;

    wire [ADD_ID_WIDTH-1:0]bid;
    wire [1:0] bresp;
    wire bvalid;
    reg bready;


	// Instantiate the Unit Under Test (UUT)
	mem_slave_top_module uut (
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
		.rid(rid),
		.rdata(rdata),
		.rresp(rresp),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
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
        .wid(wid),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),
        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;

		arid = 0;
		araddr = 0;
		arlen = 0;
		arsize = 0;
		arburst = 0;
		arlock = 0;
		arcache = 0;
		arprot = 0;
		arvalid = 0;

		rready = 0;

        awid=0;
        awaddr = 0;
        awlen = 0;
        awsize = 0;
        awburst = 0;
        awlock = 0;
        awcache = 0;
        awprot = 0;
        awvalid = 0;

        wid = 0;
        wdata = 0;
        wstrb=0;
        wlast=0;
        wvalid = 0;

        bready=1;

		// Wait 100 ns for global reset to finish
		#100;

        //----------------------- memory write template---------------------------------
        //mem_axi_write(size, length, addr, id, strobe);
        //mem_axi_read(size, length, addr, id);

        mem_axi_write(`AX_SIZE_1, `AX_LEN_1, 0, 0, {(1<<`AX_SIZE_4){1'b1}});
        mem_axi_write(`AX_SIZE_2, `AX_LEN_1, 1, 0, {(1<<`AX_SIZE_4){1'b1}});
        mem_axi_write(`AX_SIZE_2, `AX_LEN_2, 3, 0, {(1<<`AX_SIZE_4){1'b1}});
        // mem_axi_write(`AX_SIZE_1, `AX_LEN_1, 0, 0, {(1<<`AX_SIZE_4){1'b1}});
        // mem_axi_write(`AX_SIZE_2, `AX_LEN_1, 1, 0, {(1<<`AX_SIZE_4){1'b1}});
        // mem_axi_write(`AX_SIZE_4, `AX_LEN_4, 3, 0, {(1<<`AX_SIZE_4){1'b1}});

		mem_axi_read(`AX_SIZE_1, `AX_LEN_1,0,0);
		mem_axi_read(`AX_SIZE_2, `AX_LEN_1,1,0);
		mem_axi_read(`AX_SIZE_2, `AX_LEN_2,3,0);

	end


	initial begin
        clk = 0;
        forever begin
            #5 clk <= ~clk;
        end
    end

    task mem_axi_write;
        input [31:0] axi_size;
        input [31:0] axi_len;
        input [31:0] axi_addr;
        input [31:0] axi_awid;
        input [128-1:0] axi_strobe;

        integer burst_count;
        integer byte_idx;
        integer bit_idx;

        reg [7:0] data_byte;

        begin

            @(posedge clk);
            #1;
            awid = axi_awid;
            awvalid = 1;
            awaddr = axi_addr;
            awsize = axi_size;
            awlen = axi_len;

            wid = {32{1'bx}};
            wdata = {32{1'bx}};
            wstrb={MAX_BYTE_SIZE{1'bx}};      // wstrb max
            wlast={32{1'bx}};
            wvalid = 0;


            while (awready == 0) begin
                @(posedge clk);
            end

`ifdef TEST_DEBUG
        $display(" write address at time %d, addr %x", $time, awaddr);
`endif

            @(posedge clk);
            #1;
            awvalid = 0;
            awid = {32{1'bx}};
            awaddr = {32{1'bx}};
            awsize = {32{1'bx}};
            awlen = {32{1'bx}};

            wid = {32{1'bx}};
            wdata = {MAX_BIT_SIZE{1'bx}};
            wstrb={MAX_BYTE_SIZE{1'bx}};
            wlast={32{1'bx}};
            wvalid = 0;

// Note=======================
/*
    data passed during a write transaction is always equal to mod 256 of absolute byte addressible location
    this is done to help verification at read master
*/


            for(burst_count = 0; burst_count <=axi_len;burst_count = burst_count + 1 ) begin
                @(posedge clk);
                #1;
                wid = axi_awid;
                wvalid = 1;
                wstrb = axi_strobe;
                for(byte_idx=0; byte_idx< (1<<(axi_size)); byte_idx=byte_idx + 1) begin
                    data_byte = axi_addr%256 + burst_count * (1<< axi_size) + byte_idx;
                    for(bit_idx = 0; bit_idx < 8 ; bit_idx = bit_idx + 1) begin
                        wdata[( byte_idx) *8 + bit_idx] = data_byte[bit_idx];
                    end
                end
                if(burst_count == axi_len) begin
                    wlast = 1;
                end
                else begin
                    wlast = 0;
                end
                while(wready == 0) begin
                    @(posedge clk);
                end
`ifdef TEST_DEBUG
                $display(" write data at time %d, data %x", $time, wdata);
`endif
            end

            @(posedge clk);
            #1;
            awvalid = 0;
            awid = {32{1'bx}};
            awaddr = {32{1'bx}};
            awsize = {32{1'bx}};
            awlen = {32{1'bx}};

            wid = {32{1'bx}};
            wdata = {MAX_BIT_SIZE{1'bx}};
            wstrb={MAX_BYTE_SIZE{1'bx}};
            wlast={32{1'bx}};
            wvalid = 0;

        end

    endtask

    task mem_axi_read;
        input [31:0] axi_size;
        input [31:0] axi_len;
        input [31:0] axi_addr;
        input [31:0] axi_arid;

        integer burst_count;
        integer byte_idx;
        integer bit_idx;
        //reg [7:0] data_byte;

        begin

            @(posedge clk);
            #1;
            arid = axi_arid;
            arvalid = 1;
            araddr = axi_addr;
            arsize = axi_size;
            arlen = axi_len;
            rready = 0;


            while (arready == 0) begin
                @(posedge clk);
            end

`ifdef TEST_DEBUG
        $display(" Read address at time %d, addr %x", $time, araddr);
`endif

            @(posedge clk);
            #1;
            arvalid = 0;
            arid = {32{1'bx}};
            araddr = {32{1'bx}};
            arsize = {32{1'bx}};
            arlen = {32{1'bx}};
            rready =1;
// Note=======================
/*
    data passed during a write transaction is always equal to mod 256 of absolute byte addressible location
    this is done to help verification at read master
*/


            for(burst_count = 0; burst_count <=axi_len;burst_count = burst_count + 1 ) begin
                @(posedge clk);
                if(rvalid==1) begin

`ifdef TEST_DEBUG
                    $display(" REad data at time %d, data %x", $time, rdata);
`endif
                end
                else
                    burst_count=burst_count-1;
            end

            @(posedge clk);
            #1;
            arvalid = 0;
            arid = {32{1'bx}};
            araddr = {32{1'bx}};
            arsize = {32{1'bx}};
            arlen = {32{1'bx}};

            rready = 0;

        end

    endtask

endmodule

