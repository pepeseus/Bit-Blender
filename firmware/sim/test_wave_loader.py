import cocotb
import os
import random
import sys
from math import log
import numpy as np
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from PIL import Image

HDL_TOPLEVEL = "wave_loader"            # simulation module name
TEST_MODULE = "test_wave_loader"        # python file name
SOURCES = ["xilinx_true_dual_port_read_first_1_clock_ram.v"]      # list of source files "filename.sv"


WAVE_WIDTH = 1000

PARAMS = {
  "NUM_OSCILLATORS": 2,
  "SAMPLE_WIDTH": 16,
  "BRAM_DEPTH": WAVE_WIDTH,
  "WW_WIDTH": 18,
  "MMEM_MAX_DEPTH": 1000
}
    

async def reset_dut(dut):
    """Helper function to reset the DUT."""
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5)


@cocotb.test()
async def test_update_bram(dut):
    """Test the uodate to BRAMs."""
    # send pixel columns with incrementing values, print the pixel kernel

    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    await reset_dut(dut)

    dut.wave_width_in.value = WAVE_WIDTH 

    await ClockCycles(dut.clk_in, 5)

    # rising edge of clock
    await FallingEdge(dut.clk_in)

    dut.ui_update_trig_in.value = 1

    await FallingEdge(dut.clk_in)

    dut.ui_update_trig_in.value = 0

    for i in range(10):
        for j in range(1000):
            dut.viz_index_in.value = j
            await FallingEdge(dut.clk_in)



def runner():
    """Simulate using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / filename for filename in SOURCES]
    sources.insert(0, proj_path / "hdl" / f"{HDL_TOPLEVEL}.sv")
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=HDL_TOPLEVEL,
        always=True,
        build_args=build_test_args,
        parameters=PARAMS,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel=HDL_TOPLEVEL,
        test_module=TEST_MODULE,             # python file name
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    runner()
