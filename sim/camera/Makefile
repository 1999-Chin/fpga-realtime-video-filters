# cocotb testbench for rtl/cameraCapture.v
# Run: make            (add WAVES=1 to dump a waveform for GTKWave)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(abspath ../../rtl/cameraCapture.v)
COCOTB_TOPLEVEL = cameraCapture
COCOTB_TEST_MODULES = tb_camera

include $(shell cocotb-config --makefiles)/Makefile.sim
