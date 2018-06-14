#!/bin/bash
iverilog -o testbench.exe testbench2.v mod_spi_slave.v `yosys-config --datdir/ice40/cells_sim.v`
vvp -N testbench.exe
rm -f testbench.exe
