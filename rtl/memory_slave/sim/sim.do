

vlog -sv -L work ../RTL/add_read.v +cover
vlog -sv -L work ../RTL/data_read_write.v +cover
vlog -sv -L work ../RTL/add_write.v +cover
vlog -sv -L work ../RTL/data_resp.v +cover
vlog -sv -L work ../RTL/memory_module_virtual_memory.sv +cover
vlog -sv -L work ../RTL/mem_slave_top_module.v +cover
vlog -sv -L work ./top_test.v +cover

vsim -coverage -novopt -t 1ps -sv_lib ../RTL/gb1_memory -lib work work.top_test

log -r /*

run 2000ns