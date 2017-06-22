
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

module data_write
    (
      clk,
      reset,
      awid,


      wid,
      wdata,
      wstrb,
      wlast,
      wvalid,
      wready,

      mod1_valid_in,
      mod1_ready_out,
      mod3_ready_in,
      mod3_valid_out,


      addr_in,
      id_in,
      burst_length_in,
      burst_size_in,
      burst_type_in,
      id_out,
      resp_out

    );

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
   `include "../sim/param.v"
	parameter DUMMY_MEM =0;
//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------

  localparam STATE_IDLE = 0;
  localparam STATE_TASK = 1;
  localparam STATE_BUSY = 2;
  localparam STATE_WAIT = 3;

//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    input clk;
    input reset;
    input [ADD_ID_WIDTH-1:0]awid;

    //output reg awready;

    input [ADD_ID_WIDTH-1:0]wid;
    input [DATA_WIDTH-1:0]wdata;
    input [(DATA_WIDTH>>3)-1:0]wstrb;
    input wlast;
    input wvalid;
    output reg wready;

    //Sub Module IO signals

    input mod3_ready_in;
    input mod1_valid_in;
    output reg mod3_valid_out;
    output reg mod1_ready_out;

    input [ADD_WIDTH-1:0] addr_in;
    input [BURST_LEN-1:0] burst_length_in;
    input [BURST_SIZE-1:0] burst_size_in;
    input [BURST_TYPE-1:0] burst_type_in;
    input [ADD_ID_WIDTH-1:0]id_in;

    output reg[ADD_ID_WIDTH-1:0]id_out;
    output reg[1:0]resp_out;


//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------
reg [1:0] state;
reg [1:0] next_state;
reg [DATA_WIDTH-1:0] wr_data;
reg [ADD_WIDTH-1:0] add_data;
reg [BURST_LEN-1:0] burst_length;
reg [2**BURST_SIZE-1:0] burst_size;
reg [BURST_TYPE-1:0] burst_type;
reg [(DATA_WIDTH>>3)-1:0]write_strobe;

reg last;
reg [7:0] rdata ;


//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------
initial begin
  state = STATE_IDLE;
end

 /*always @(posedge clk) begin : Clock_Edge_register_sampling
      case (state)

        STATE_IDLE : begin
         if (mod1_valid_in==1) begin
            if (wvalid==1) begin
              add_data<=address_in;
              wr_data<=wdata;
            end
            else begin
              add_data<=address_in;
            end
          end
        end

        STATE_TASK : begin


          //calling the function for data write
          if ((mod3_ready_in==1 && mod1_valid_in==1 && wvalid==1 && last==1) || (wvalid==1 && last ==0)) begin
           wr_data<=wdata;
          end
        end

        STATE_WAIT: begin
          if(wvalid==1) begin
            wr_data<=wdata;

          end
        end

        STATE_BUSY: begin
          if(mod3_ready_in==0 && mod1_valid_in==0 && wvalid==1)begin
            add_data<=address_in;
            wr_data<=wdata;
          end
          else if(mod3_ready_in==0 && mod1_valid_in==0 && wvalid==0) begin
           add_data<=address_in;
          end
        end

      endcase
  end*/

 always @(posedge clk) begin : Next_state_and_driving_outputs
     state<=next_state;
  end

    always @(*) begin : dfe
      case (state)

        STATE_IDLE :begin

          mod1_ready_out=1;
          wready = mod1_valid_in;
          mod3_valid_out =0;

          if (mod1_valid_in==1) begin
            if (wvalid==1) begin
              next_state=STATE_TASK;
            end
            else begin
              next_state=STATE_WAIT;
            end
          end
          else begin
            next_state=STATE_IDLE;
          end
        end

        STATE_TASK :begin

          mod1_ready_out = last && mod3_ready_in;
          wready = (~last || (last && mod3_ready_in && mod1_valid_in));
          mod3_valid_out = last;

          if ((mod3_ready_in==1 && mod1_valid_in==1 && wvalid==1 && last==1) || (wvalid==1 && last ==0)) begin
            next_state=STATE_TASK;
          end
           if (last==1 && mod3_ready_in ==0) begin
            next_state=STATE_BUSY;
          end
          if((mod3_ready_in==1 && last ==1 && mod1_valid_in==0) ) begin
            next_state=STATE_IDLE;
          end
          if((wvalid==0 && last==0) || (mod3_ready_in==1 && last ==1 && mod1_valid_in==1 && wvalid==0))  begin
            next_state=STATE_WAIT;
          end
        end

        STATE_BUSY: begin

          mod1_ready_out = mod3_ready_in;
          wready = mod3_ready_in && mod1_valid_in;
          mod3_valid_out = 1;

          if (mod3_ready_in==0) begin
            next_state=STATE_BUSY;
          end
          else if(mod1_valid_in==0) begin
            next_state=STATE_IDLE;
          end
          else if(wvalid==1)begin
            next_state=STATE_TASK;
          end
          else begin
            next_state=STATE_WAIT;
          end
        end

        STATE_WAIT: begin

          mod1_ready_out = 0;
          wready = 1;
          mod3_valid_out = 0;

          if(wvalid==1) begin
            next_state=STATE_TASK;

          end
          else
            next_state=STATE_WAIT;
        end

        endcase

    end

always @(posedge clk) begin
    if(next_state==STATE_TASK) begin
        if(burst_length==4'b0000) begin
          add_data = addr_in[ADD_WIDTH-1:0];
          wr_data = wdata;
          write_strobe=wstrb;
          id_out = id_in;
          burst_length = burst_length_in+1;
          burst_size = 2**burst_size_in;
          burst_type = burst_type_in;
          wr_data = wdata;
          resp_out=2'b00;
        end
        else begin
          wr_data = wdata;
          write_strobe=wstrb;
        end

`ifdef WRITE_DATA_DEBUG
        $display("Write address :  %d", add_data);
        $display("Write data :  %d", wr_data);
`endif
        if(id_out!=wid) begin
          resp_out = 2'b01;
        end
        for (int i = 0; i < burst_size; i=i+1)
        begin
          if(write_strobe[i]==1) begin

            rdata[0] = wr_data[8*i];
            rdata[1] = wr_data[8*i+1];
            rdata[2] = wr_data[8*i+2];
            rdata[3] = wr_data[8*i+3];
            rdata[4] = wr_data[8*i+4];
            rdata[5] = wr_data[8*i+5];
            rdata[6] = wr_data[8*i+6];
            rdata[7] = wr_data[8*i+7];
            //top_test.uut.memory.memory_initilaize();
			if(DUMMY_MEM==0) begin
				pred_top_tb.uut.mem_slave.memory.data_write(add_data,rdata);
			end
`ifdef WRITE_DATA_DEBUG
            $display("Address : %d , data :  %d",add_data,rdata);
`endif
          end
          add_data = add_data+1;
        end
        burst_length = burst_length-1;
        //top_test.uut.memory.data_read(address,rdata);
        //NISAL'S MEMORY
    end

    else if(next_state == STATE_WAIT) begin
       if(burst_length==4'b0000) begin
          add_data = addr_in;
          id_out = id_in;
          burst_length = burst_length_in+1;
          burst_size = 2**burst_size_in;
          burst_type = burst_type_in;
          resp_out = 2'b00;
        end
    end

    else if(next_state==STATE_IDLE) begin
      id_out = 3'b000;
      burst_length = 4'b000; //0 indicates 1 burst
      burst_size  = 3'b000;
      burst_type = 2'b00;
      resp_out = 2'b00;
    end

  end

always @(*) begin
  if(burst_length==4'b0000) begin
    last = 1;
  end
  else begin
    last = 0;
  end
end
endmodule
