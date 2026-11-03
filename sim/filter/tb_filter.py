import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def apply_input(dut, sw, r, g, b):
    """Helper function to apply inputs and wait for one clock cycle."""
    dut.sw.value = sw
    dut.r_raw.value = r
    dut.g_raw.value = g
    dut.b_raw.value = b
    await RisingEdge(dut.clk_25m)
    # Wait 1ns to allow internal logic to settle before sampling output
    await Timer(1, "ns")

@cocotb.test()
async def test_filter_all_modes(dut):
    """Test all operating modes of the Filter module."""

    # 1. Initialize 25MHz clock (40ns period)
    cocotb.start_soon(Clock(dut.clk_25m, 40, unit="ns").start())

    # --- Test Case 0: No Filter (00000) ---
    await apply_input(dut, 0b00000, 0xA, 0x5, 0x2)
    assert (dut.r_filtered.value == 0xA and 
            dut.g_filtered.value == 0x5 and 
            dut.b_filtered.value == 0x2), "No Filter Mode Failed"
    dut._log.info("Mode 0: No Filter Passed")

    # --- Test Case 1: Red Isolation (00001) ---
    # Case: Red dominant color (R=15, G=2, B=2) -> Should keep original color
    await apply_input(dut, 0b00001, 0xF, 0x2, 0x2)
    assert dut.r_filtered.value == 0xF, "Red Isolation (Keep Color) Failed"
    
    # Case: Other color dominant (R=2, G=15, B=2) -> Should convert to Grayscale
    # Expected Gray = (2*5 + 15*9 + 2*2) >> 4 = 149 >> 4 = 9
    await apply_input(dut, 0b00001, 0x2, 0xF, 0x2)
    assert int(dut.r_filtered.value) == 9, f"Red Isolation (Gray) Failed: Got {int(dut.r_filtered.value)}"
    dut._log.info("Mode 1: Red Isolation Passed")

    # --- Test Case 2: Green Isolation (00010) ---
    await apply_input(dut, 0b00010, 0x2, 0xF, 0x2)
    assert dut.g_filtered.value == 0xF, "Green Isolation Passed"

    # --- Test Case 3: Blue Isolation (00100) ---
    # Verilog logic: (b_raw > r_raw) && (b_raw > g_raw - 1)
    await apply_input(dut, 0b00100, 0x2, 0x2, 0xF)
    assert dut.b_filtered.value == 0xF, "Blue Isolation Passed"

    # --- Test Case 4: Grayscale (01000) ---
    # Input: R=15, G=15, B=0 -> Gray = (15*5 + 15*9 + 0) >> 4 = 210 >> 4 = 13
    await apply_input(dut, 0b01000, 0xF, 0xF, 0x0)
    assert int(dut.r_filtered.value) == 13, "Grayscale Mode Failed"
    dut._log.info("Mode 8: Grayscale Passed")

    # --- Test Case 5: Thresholding (10000) ---
    # Gray > 8 (Result should be White/0xF)
    await apply_input(dut, 0b10000, 0xF, 0xF, 0xF)
    assert int(dut.r_filtered.value) == 0xF, "Threshold High Failed"
    
    # Gray <= 8 (Result should be Black/0x0)
    await apply_input(dut, 0b10000, 0x1, 0x1, 0x1)
    assert int(dut.r_filtered.value) == 0x0, "Threshold Low Failed"
    dut._log.info("Mode 16: Threshold Passed")

    # --- Test Case 6: Default (More than one switch active) ---
    await apply_input(dut, 0b11111, 0xF, 0xF, 0xF)
    assert int(dut.r_filtered.value) == 0, "Default Black Screen Failed"
    dut._log.info("Default Mode: Black Screen Passed")

    dut._log.info("All test cases completed successfully!")


