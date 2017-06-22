
// ************************************************************************************************
//
// PROJECT      :   AXI_ADDRESS_READ
// PRODUCT      :   AXI meomory slave
// FILE         :   <File Name/Module Name>
// AUTHOR       :   <Author's name>
// DESCRIPTION  :   Accepts the address from master nand holds it. If data read is not busy pass module
//
// ************************************************************************************************
//
// REVISIONS:
//
//	Date			Developer	Description
//	----			---------	-----------
//  09 Apr 2014		Start date
//
//**************************************************************************************************

`timescale 1ns / 1ps

module data_read
    (
      clk,
      reset,

      rid,
      rdata,
      rresp,
      rlast,
      rvalid,
      rready,

      raddr_in,
      rlen_in,
      rsize_in,
      rburst_in,
      rid_in,

      mod1_ready_out,
      mod1_valid_in

      //address,
      //data,

    );

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
   `include "../sim/param.v"
	parameter DUMMY_MEM = 0;
//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------

  localparam STATE_IDLE = 0;
  localparam STATE_TASK = 1;
  localparam STATE_WAIT = 2;
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    input clk;
    input reset;

    output reg[ADD_ID_WIDTH-1:0]rid;
    output reg[DATA_WIDTH-1:0]rdata;
    output reg[1:0]rresp;
    output reg rlast;
    output reg rvalid;
    input rready;


    input [ADD_WIDTH-1:0]raddr_in;
    input [BURST_LEN-1:0]rlen_in;
    input [BURST_SIZE-1:0]rsize_in;
    input [BURST_TYPE-1:0]rburst_in;
    input reg[ADD_ID_WIDTH-1:0]rid_in;


    //Sub Module IO signals
    output reg mod1_ready_out;
    input mod1_valid_in;
    reg [ADD_WIDTH-1:0] address;
    //reg [REGISTER_SIZE-1:0] data;

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------
reg [1:0] state;
reg [1:0] next_state;
reg [BURST_LEN:0] burst_length;
reg [2**BURST_SIZE-1:0] burst_size;
reg [BURST_TYPE-1:0] burst_type;

reg [7:0]mem_data = 8'd0;

//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------
  initial begin
    state = STATE_IDLE;
  end

 /*always @(posedge clk) begin
      case (state)
        STATE_IDLE : begin
          if(mod1_valid_in == 1) begin
            //address<=raddr_in;
            rid<=raddr_in;
            burst_length <= rlen_in; //0 indicates 1 burst
            burst_size <= 2**rsize_in;
            burst_type<=rburst_in;
          end
          else begin
            rid<= 3'b000;
            burst_length <= 4'b000; //0 indicates 1 burst
            burst_size <= 3'b000;
            burst_type<= 2'b000;
          end
        end

        STATE_TASK : begin
          if (rready==1 && mod1_valid_in==1 && burst_length==4'b000) begin
              //address<=raddr_in;
              rid<=raddr_in;
              burst_length <= rlen_in;
              burst_size <= 2**rsize_in;
              burst_type<=rburst_in;
          end
          //else if (rready==1 && burst_length > 8'b000) begin
              //address<=address+burst_size; //SIZE OF BURST
          //end
        end

        STATE_WAIT :begin
          if (rready==1 && mod1_valid_in==1 && burst_length==4'b000) begin
              //address<=raddr_in;
              rid<=raddr_in;
              burst_length <= rlen_in;
              burst_size <= 2**rsize_in;
              burst_type<=rburst_in;
          end
          //else if (rready==1 && burst_length > 8'b000) begin
              //address<=address+burst_size; //SIZE OF BURST
          //end
        end
      endcase
  end */

 always @(posedge clk) begin
     state<=next_state;
  end

  always @(*) begin
      case (state)
        STATE_IDLE :begin
          rvalid =0;
          mod1_ready_out = 1;
          rlast=0;
          if (mod1_valid_in==1) begin
            next_state=STATE_TASK;
          end
          else begin
            next_state=STATE_IDLE;
          end
        end

        STATE_TASK :begin
          //top_test.uut.memory.data_read(address,rdata);
          if (rready==1) begin
            rvalid =1;

            if(mod1_valid_in==0 && burst_length == 4'b0000) begin
              next_state=STATE_IDLE;
            end
            else begin
              next_state=STATE_TASK;
            end

            if(burst_length==4'b0000) begin
                mod1_ready_out=1;
                rlast=1;
            end
            else begin
                mod1_ready_out=0;
                rlast = 0;
            end

          end
          else begin
            rvalid=0;
            rlast=0;
            mod1_ready_out=0;
            next_state=STATE_WAIT;
          end
        end

        STATE_WAIT :begin
          if (rready==1) begin
            rvalid=1;
            if(mod1_valid_in==0 && burst_length==4'b0000) begin
              next_state=STATE_IDLE;
            end
            else begin
              next_state=STATE_TASK;
            end

            if(burst_length==4'b0000) begin
                mod1_ready_out=1;
                rlast=1;
            end
            else begin
                mod1_ready_out=0;
                rlast=0;
            end
          end
          else begin
            rvalid=0;
            rlast=0;
            mod1_ready_out=0;
            next_state=STATE_WAIT;
          end
        end

        endcase

    end

	
  always @(posedge clk) begin
    if(next_state==STATE_TASK) begin

        if(burst_length==4'b0000) begin
          address = raddr_in[ADD_WIDTH-1:0];
          rid = rid_in;
          burst_length = rlen_in+1;
          burst_size = 2**rsize_in;
          burst_type = rburst_in;
        end
        //else begin
          //address = address+burst_size;
        //end
        //top_test.uut.memory.data_read(address,rdata);
        //NISAL'S MEMORY
`ifdef READ_DATA_DEBUG
        $display("Read address :  %d", address);
`endif

        for (int i = 0; i < burst_size; i=i+1)
        begin
			if(DUMMY_MEM==0) begin
				$root.data_read(address,mem_data);
			end
          rdata[8*i] = mem_data[0];
          rdata[8*i+1] = mem_data[1];
          rdata[8*i+2] = mem_data[2];
          rdata[8*i+3] = mem_data[3];
          rdata[8*i+4] = mem_data[4];
          rdata[8*i+5] = mem_data[5];
          rdata[8*i+6] = mem_data[6];
          rdata[8*i+7] = mem_data[7];
`ifdef READ_DATA_DEBUG
          $display("Address : %d , data :  %d",address,mem_data);
`endif
          address= address+1;
        end
        burst_length = burst_length-1;
        rresp = 2'b00;
`ifdef READ_DATA_DEBUG
        $display("Read data :  %d", rdata);
`endif
    end
    else if(next_state==STATE_IDLE) begin
      rid = 3'b000;
      burst_length = 4'b0000; //0 indicates 1 burst
      burst_size  = 3'b000;
      burst_type = 2'b00;
    end
  end

endmodule