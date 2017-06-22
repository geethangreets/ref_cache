#vdel -all
#vlib work
#vmap work work

vlog -work work ../rtl/verif/fifo_write_driver.v
vlog -work work ../rtl/verif/inf_monitor.v
vlog -work work ../rtl/geet_fifo_almost_full.v

vlog -work work ../rtl/cache_conf_stage.v
vlog -work work ../rtl/num_val_clines_generator.v
vlog -work work ../rtl/num_val_clines_generator_ch.v
vlog -work work ../rtl/cache_data_mem.v
vlog -sv -work work ../rtl/tag_memory_write_first.sv
vlog -work work ../rtl/compare_tags_new.v
vlog -work work ../rtl/new_age_converter.v
vlog -work work ../rtl/age_memory.v
vlog -work work ../rtl/cache_dest_enable.v
vlog -work work ../rtl/tag_read_stage.v
vlog -work work ../rtl/tag_compare_stage.v
vlog -sv -work work ../rtl/cache_set_input.sv
vlog -sv -work work ../rtl/cache_bank_core.sv
vlog -work work ../rtl/inter_cache_pipe_hit_pipe.v


vlog -work work -mixedsvvh +define+INSERT_MONITORS ../tb/cache_tb.sv


vsim -voptargs="+acc" -t 1ps -lib work cache_tb