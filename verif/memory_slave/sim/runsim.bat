if exist work (
	rmdir /S /Q work 2> nul
)

rem set SV_file=inter_pred_iface.svi 


vlib work
echo vlib work


rem vlog -L work -sv -dpiheader dpiheader.h %SV_file%




rem vlog  "C:/Xilinx/14.6/ISE_DS/ISE//verilog/src/glbl.v"


vsim -do sim.do


echo Done !