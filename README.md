icozsoc
=======

IcoSoc port for the icezero FPGA shield.

NOTE: the RASPIF parallel bus to the raspberry pi zero has been removed 
and replaced with a simple UART from https://github.com/lawrie/icotools/tree/master/icosoc

Therefor the built-in IcoSoc debugging functionality is not available as is.


original README:

      *************************************************************
      * IcoSoC -- A PicoRV32-based SoC generator for the IcoBoard *
      *************************************************************


The IcoBoard is a Raspberry PI hat featuring the ICE40 HX8K fpga. It
can be programmed using the IceStorm Open Source FPGA flow:

http://icoboard.org/
http://www.clifford.at/icestorm/

This SoC generator creates SoCs using the PicoRV32 processor core that run on
the IcoBoard. Multiple IO standard interfaces are supported. The SoC has a
console interface to the Raspberry Pi. (Run "icoprog -zZc2" on the Raspberry
Pi to connect to the console. Note that the SoC stops when the console output
buffer is full.)

It is certainly possible to run the entire toolchain (including SoC generation)
on the Raspberry Pi, but for this manual we assume that the SoC generation
happens on a separate workstation and only "icoprog" is run directly on the
Raspberry Pi.

The generated makefiles assume that the Raspberry Pi can be connected to with
"ssh pi@raspi" without password authentication (i.e. authentication using SSH
keys). Note that "ssh pi@raspi" must connect to the Raspberry Pi within a few
seconds, otherwise the SoC bootloader will timeout between programming the
FPGA and uploading the application image.

Simply change into one of the examples/* directories and run "make run" to
build and upload a SoC hardware/software bundle. You'll need the iCE40 and
RISC-V toolchains installed on your system, as outlined below.


Installing the IceStorm Flow
============================

The IceStorm flow consists of the IceStorm Tools, Arachne-PNR, and Yosys.
Follow the instructions on the IceStorm website to build the flow:

	http://www.clifford.at/icestorm/#install


Installing the RISC-V Toolchain
===============================

Follow the instructions in the PicoRV32 documentation:
https://github.com/cliffordwolf/picorv32#building-a-pure-rv32i-toolchain

IcoSoC can be configured with different ISA features (with and without
compressed ISA, with or without multiply/divide instructions). To support
all variations, different compiler toolchains must be built. To build all
of them simply run:

	git clone git@github.com:cliffordwolf/picorv32.git
	cd picorv32
	make download-tools
	make -j$(nproc) build-tools


IcoSoC Configuration File Format
================================

See examples/ for some example SoCs. Each IcoSoC project has a Makefile
that includes icosoc.mk, has a rule to create it using icosoc.py, and
has a rule to build an appimage.hex file. It also must have an icosoc.cfg
file that configures the SoC.

Use examples/hello/Makefile and examples/hello/icosoc.cfg as a templates.

The icosoc.cfg file has a "global section" that contains statements that
configure the overall SoC, and "module sections" for each peripheral module.


IcoSoC Global Config Section
============================

The following statements are supported in the global section:

board <board_name>
------------------

Sets the board type. Currently supported values are "icoboard_gamma"
and "icoboard".

compressed_isa
--------------

Enable support for the RISC-V Compressed ISA. This will result in smaller
application images, but require more FPGA resources for the processor core.

muldiv_isa
----------

Enable support for multiply/divide instructions. This will significantly
increase the size of the processor core.

flashmem
--------

Map SPI flash into processor memory. Byte 0 of the flash is at 0x40000000.

flashpmem
---------

Use SPI flash as program memory. Executing code from the SPI flash is very
slow! But it enables much larger programs to be used with the SoC. This
will modify the boot loader and a different linker script will be used to
link the program. Everything in the ELF section .text.sram will be placed
in SRAM. Make sure that performance critical functions are placed in this
ELF section.

This implies the "flashmem" option. In addition to the mapping at 0x40000000
this will map everything above 0x100000 (1MB) in the flash to 0x100000 in
the processor address space.

noflashboot
-----------

Do not attempt to load application from flash after timeout. Set when
connecting via SSH (e.g. from "make run") may take longer than the timeout.

fastflashboot
-------------

Boot from flash right away. Do not wait for a firmware image via the console
interface.


IcoSoC Module Sections
======================

A module section starts with "mod <mod_type> <mod_name>". See the mod_*
directories in this directory for supported module types. The <mod_name>
can be any identifier. For example consider the following module section:

	mod gpio leds
	  address 4
	  connect IO pmod2 pmod1

This will create a GPIO controller named "leds". The register file for
that controller starts at 0x20040000 (0x20000000 + <addr> * 0x10000).

The port IO of the peripheral is connected to the pins of the PMOD ports
number 2 and 1. (The name "IO" is specific to the module type. The module
type "gpio" only specifies a port "IO".)

This will also create functions for accessing that peripheral module
in icosoc.h and icosoc.c. The prefix "icosoc_<mod_name>_" is used for
the function names.

