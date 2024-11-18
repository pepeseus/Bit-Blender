import cocotb
import os
import sys
from pathlib import Path
from cocotb.clock import Clock
from math import log
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
import logging
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout

@cocotb.test()
async def test_buffer(dut):
    
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    dut.rst_in.value = 1 
    await ClockCycles(dut.clk_in, 10)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 10)

    for hcount in range(10):
            
        dut.hcount_in.value = hcount
        dut.vcount_in.value = 0
        dut.data_valid_in.value = 1
        dut.pixel_data_in.value = 0x0000
        await ClockCycles(dut.clk_in,1)


    for hcount in range(10):
            
        dut.hcount_in.value = hcount
        dut.vcount_in.value = 1
        dut.data_valid_in.value = 1
        dut.pixel_data_in.value = 0x7777
        await ClockCycles(dut.clk_in,1)


    for hcount in range(10):
            
        dut.hcount_in.value = hcount
        dut.vcount_in.value = 2
        dut.data_valid_in.value = 1
        dut.pixel_data_in.value = 0x5555
        await ClockCycles(dut.clk_in,1)

    await ClockCycles(dut.clk_in, 10)

def is_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "line_buffer.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="line_buffer",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="line_buffer",
        test_module="test_buffer",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()