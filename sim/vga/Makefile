# cocotb testbench for rtl/vga.v
# Run: make            (add WAVES=1 to dump a waveform for GTKWave)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(abspath ../../rtl/vga.v)
COCOTB_TOPLEVEL = vga
COCOTB_TEST_MODULES = tb_vga

include $(shell cocotb-config --makefiles)/Makefile.sim
