# cocotb testbench for rtl/filter.v
# Run: make            (add WAVES=1 to dump a waveform for GTKWave)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(abspath ../../rtl/filter.v)
COCOTB_TOPLEVEL = filter
COCOTB_TEST_MODULES = tb_filter

include $(shell cocotb-config --makefiles)/Makefile.sim
