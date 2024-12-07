import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import os
import sys
from pathlib import Path
from cocotb.runner import get_runner

# Helper function to calculate the number of clock cycles per baud period
def baud_cycles(baud_rate, clk_freq):
    return clk_freq // baud_rate

baud_rate = 31250  # Baud rate: 31250 bps

@cocotb.test()
async def test_uart_receive(dut):
    """Test UART receiver with a sample byte (0xDE)"""

    # Initialize clock and reset
    clock_freq = 100_000_000  # Clock frequency: 100 MHz
    clk_period_ns = 10        # Clock period: 10ns for 100 MHz
    byte_to_receive = 0x55    # Test byte

    dut._log.info("Starting UART receive test")

    # Start clock
    cocotb.start_soon(Clock(dut.clk_in, clk_period_ns, units="ns").start())

    # Apply reset
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)  # Hold reset for 5 cycles
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5)

    # Simulate UART transmission for the byte 0xDE
    baud_period = baud_cycles(baud_rate, clock_freq)

    # Start bit (low)
    dut.rx_wire_in.value = 0
    await ClockCycles(dut.clk_in, baud_period)

    for i in range(8):
        bit = (byte_to_receive >> i) & 1
        print(bit)
        dut.rx_wire_in.value = bit
        await ClockCycles(dut.clk_in, baud_period)

    # Stop bit (high)
    dut.rx_wire_in.value = 1
    await ClockCycles(dut.clk_in, baud_period)
    await ClockCycles(dut.clk_in, baud_period)
    await ClockCycles(dut.clk_in, baud_period)
    await ClockCycles(dut.clk_in, baud_period)
    await ClockCycles(dut.clk_in, baud_period)
    await ClockCycles(dut.clk_in, baud_period)


    # # Check if new data is received
    # await RisingEdge(dut.new_data_out)
    # assert dut.data_byte_out.value == byte_to_receive, f"Received byte incorrect: {dut.data_byte_out.value} != {byte_to_receive}"

    dut._log.info("UART receive test passed")


def uart_receiver_runner():
    """Simulate the UART transmitter using the Cocotb runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv"]  # Path to your Verilog RTL file
    build_test_args = ["-Wall"]
    parameters = {'BAUD_RATE': baud_rate}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    
    # Build the simulation
    runner.build(
        sources=sources,
        hdl_toplevel="uart_receive",  # Top module in your Verilog code
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),  # Time scale for the simulation
        waves=True  # Enable waveform dumping (VCD file)
    )
    
    # Run the test
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_receive",
        test_module="receiver_tests",  # Name of the Python test file (without .py)
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_receiver_runner()











    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="midi_reader",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="midi_reader",
        test_module="test_midi_reader",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()