import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def vga_test(dut):
    # 1. Start the clock
    cocotb.start_soon(Clock(dut.clk_25mhz, 40, unit="ns").start())


    # 2. FORCE initial values into the Verilog registers
    # This bypasses the need for an 'initial' block in vga.v
    dut.h_count.value = 0
    dut.v_count.value = 0
    dut.hsync.value = 1
    dut.vsync.value = 1
    dut.active_video_delay.value = 0
   
    # 3. Initialize the input data
    dut.bram_data.value = 0


    # Wait a few cycles for the forced values to propagate
    for _ in range(5):
        await RisingEdge(dut.clk_25mhz)


    cocotb.log.info("--- Starting Verification ---")


    # 4. Run the check
    for i in range(2000):
        await RisingEdge(dut.clk_25mhz)
       
        # We use .integer to safely read the value
        h = dut.h_count.value.to_unsigned()
        v = dut.v_count.value.to_unsigned()
        addr = dut.bram_addr.value.to_unsigned()
       
        expected_addr = ((v >> 1) * 320) + (h >> 1)
       
        if h < 640 and v < 480:
            assert addr == expected_addr, f"Mismatch at H={h}: Got {addr}, expected {expected_addr}"
   
    cocotb.log.info("Successfully verified address logic without modifying RTL!")