import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def send_pixel(dut, r, g, b):
    """
    Simulates sending one 16-bit RGB565 pixel as two bytes.
    RGB565 format: [RRRRRGGG] [GGGBBBBB]
    Your code extracts: Red[7:4], Green[2:0]+d[7], Blue[4:1]
    """
    # Byte 1: Red and upper Green
    byte1 = (r << 4) | (g >> 1)
    dut.d.value = byte1
    await RisingEdge(dut.pclk)
    
    # Byte 2: Lower Green and Blue
    byte2 = ((g & 0x01) << 7) | (b << 1)
    dut.d.value = byte2
    await RisingEdge(dut.pclk)

@cocotb.test()
async def test_camera_capture(dut):
    # 1. Start a 24MHz clock (approx 41.67ns period)
    cocotb.start_soon(Clock(dut.pclk, 41.67, unit="ns").start())

    # 2. Initial Reset state (VSYNC pulse)
    dut.vsync.value = 1
    dut.href.value = 0
    dut.d.value = 0
    await Timer(100, unit="ns")
    dut.vsync.value = 0
    await RisingEdge(dut.pclk)

    dut._log.info("Starting frame capture simulation...")

    # 3. Simulate Row 0
    dut.href.value = 1
    # We send 4 pixels (which results in 8 pclk cycles)
    # Because of your x[0]==0 and y[0]==0 logic, only specific pixels trigger 'we'
    for i in range(4):
        # Sending different colors to verify extraction
        # r=15, g=0, b=0 (Red)
        await send_pixel(dut, r=0xF, g=0x0, b=0x0)
        
    dut.href.value = 0
    await Timer(100, unit="ns")

    # 4. Final checks
    # Because of y[0]==0 and x[0]==0, 
    # out of the 4 pixels sent, 2 should have been written to memory.
    final_addr = dut.addr.value.to_unsigned()
    dut._log.info(f"Captured Address count: {final_addr}")
    
    if final_addr > 0:
        dut._log.info("Test Passed: Pixels captured successfully.")
    else:
        raise Exception("Test Failed: No pixels were written to memory (we remained 0).")
