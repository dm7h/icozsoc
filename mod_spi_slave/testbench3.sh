#!/bin/bash
iverilog -o testbench.exe testbench3.v ../common/icosoc_crossclkfifo.v `yosys-config --datdir/ice40/cells_sim.v`
vvp -N testbench.exe
rm -f testbench.exe
