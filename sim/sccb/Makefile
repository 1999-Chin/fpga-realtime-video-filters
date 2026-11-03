# cocotb testbench for rtl/sccb.v
# Run: make            (add WAVES=1 to dump a waveform for GTKWave)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(abspath ../../rtl/sccb.v)
COCOTB_TOPLEVEL = sccb
COCOTB_TEST_MODULES = tb_sccb

include $(shell cocotb-config --makefiles)/Makefile.sim
