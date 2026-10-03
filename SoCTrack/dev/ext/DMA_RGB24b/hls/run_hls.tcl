# Vitis HLS : creation du projet DMA RGB mm2s
# usage : vitis_hls -f run_hls.tcl

open_project -reset DMA24b_mm2s_prj
set_top DMA24bUnit_mm2s

add_files    ../src/DMA24b_mm2s.cpp -cflags "-I../src"
add_files -tb ../src/tb.cpp         -cflags "-I../src"

open_solution -reset "solution1"
set_part {xc7z020clg400-1}
create_clock -period 6.66 -name default   ;# 150 MHz

csim_design
csynth_design
#cosim_design -trace_level all
#export_design -format ip_catalog

exit
