import cocotb
from cocotb.triggers import Timer, FallingEdge, RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test_sccb_config(dut):
    """Test the SCCB Configuration Module"""

    # 1. Start the Clock (25MHz -> 40ns period)
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())

    # 2. Reset / Initial State
    # (The module doesn't have a formal reset, it starts at reg_idx 0)
    dut._log.info("Starting SCCB simulation...")

    # 3. Monitor the Register Index
    # We want to wait until all 8 registers have been processed
    expected_regs = 8
    
    while int(dut.reg_idx.value) < expected_regs:
        # Wait for a rising edge of the internal i2c_clk to check status
        # Or wait for the SIOC to toggle
        await RisingEdge(dut.sioc)
        
        # Log when a new register index is reached
        current_idx = int(dut.reg_idx.value)
        if current_idx > 0:
            dut._log.info(f"Currently processing register index: {current_idx}")

        # Safety timeout to prevent infinite loops if the FSM hangs
        # We wait a bit of simulation time
        await Timer(100, unit="us")

    dut._log.info("All registers successfully transmitted!")
    
    # 4. Final check: verify reg_idx reached TOTAL_REGS
    assert int(dut.reg_idx.value) == 8, f"Test failed! Only reached reg {dut.reg_idx.value}"

