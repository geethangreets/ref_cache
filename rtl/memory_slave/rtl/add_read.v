
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

module add_read
    (
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

      address_out,
      mod2_ready_in,
      mod2_valid_out,
      id_out,
      len_out,
      size_out,
      burst_out

    );

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
   `include "../sim/param.v"

//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------

  localparam STATE_IDLE = 0;
  localparam STATE_BUSY = 1;
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    input clk;
    input reset;
    input [ADD_ID_WIDTH-1:0]arid;
    input [ADD_WIDTH-1:0]araddr;
    input [BURST_LEN-1:0]arlen;
    input [BURST_SIZE-1:0]arsize;
    input [BURST_TYPE-1:0]arburst;
    input [1:0]arlock;
    input [3:0]arcache;
    input [2:0]arprot;
    input  arvalid;
    output reg arready;

    //Sub Module IO signals
    output reg [ADD_WIDTH-1:0] address_out;
    output reg [ADD_ID_WIDTH-1:0]id_out;
    output reg [BURST_LEN-1:0]len_out;
    output reg [BURST_SIZE-1:0]size_out;
    output reg [BURST_TYPE-1:0]burst_out;
    input mod2_ready_in;
    output reg mod2_valid_out;


//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//---------------------------------------------------------------------------------------------------------------------
reg [1:0] state;
reg [1:0] next_state;



//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------
initial begin
  state = STATE_IDLE;
end

 always @(posedge clk) begin : Clock_Edge_register_sampling
      case (state)

        STATE_IDLE : begin
          if(arvalid == 1) begin
            address_out<=araddr;
            id_out <=arid;
            len_out <=arlen;
            size_out<=arsize;
            burst_out<=arburst;
          end
        end

        STATE_BUSY : begin
          if(arvalid == 1 && mod2_ready_in) begin
            address_out<=araddr;
            id_out <=arid;
            len_out <=arlen;
            size_out<=arsize;
            burst_out<=arburst;
          end
        end
      endcase
  end

 always @(posedge clk) begin : Next_state_and_driving_outputs
     state<=next_state;
  end

    always @(*) begin : dfe
      case (state)
        STATE_IDLE :begin

          arready=1;
          mod2_valid_out=0;

          if (arvalid==1) begin
            next_state=STATE_BUSY;
          end
          else begin
            next_state=STATE_IDLE;
          end
        end

        STATE_BUSY :begin
          if (arvalid==1) begin
            next_state=STATE_BUSY;
          end
          else if (mod2_ready_in==0) begin
            next_state=STATE_BUSY;
          end
          else begin
            next_state=STATE_IDLE;
          end

          if (mod2_ready_in==1) begin
            mod2_valid_out=1;
            arready=1;
          end
          else begin
            mod2_valid_out=0;
            arready=0;
          end

        end
        endcase

    end




endmodule
