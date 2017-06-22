

// ************************************************************************************************
//
// PROJECT      :   Memory Controller
// PRODUCT      :   Virtual Memory - using c++
// FILE         :   memory.sv
// AUTHOR       :   NM
// DESCRIPTION  :
// VERSION      : 1.00
// ************************************************************************************************
//
// REVISIONS:
//
//    11/04/2014      NM
//**************************************************************************************************

`timescale 1ns / 1ps

module memory_module_virtual_memory();

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------

`include "../sim/param.v"

//---------------------------------------------------------------------------------------------------------------------
// localparam definitions
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------------------------------------------------------

    import "DPI-C"  function void memory_init();
    import "DPI-C"  function byte memory_read(int location);
    import "DPI-C"  function void memory_write(int location, byte data);
    import "DPI-C"  function int  add_ref_DPB(int base_addr, int poc, int height, int width, int bit_depth, int SubWidthC, int SubHeightC);

//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------
    task memory_initialize;
        memory_init();
    endtask


    task data_read;
        input [ADD_WIDTH-1 : 0]  location;
        output [8-1 : 0] data;
        begin
            data = memory_read(location);
        end

    endtask

    task data_write;
        input [ADD_WIDTH-1 : 0]  location;
        input [8-1 : 0] data;
        begin
            memory_write(location, data);
        end

    endtask
    
    task init_ref_buffer;
        input [32-1 : 0]  base_addr;
        input [32-1 : 0]  poc;
        input [32-1 : 0]  height;
        input [32-1 : 0]  width;
        input [32-1 : 0]  bit_depth;
        input [32-1 : 0]  SubWidthC;
        input [32-1 : 0]  SubHeightC;
        
        logic return_val;
        begin
            return_val = add_ref_DPB(base_addr, poc, height, width, bit_depth, SubWidthC, SubHeightC);
        end
    endtask


endmodule











