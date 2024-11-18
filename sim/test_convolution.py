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
from PIL import Image, ImageFilter

w, h = 9, 9

def make_image_convolution_black(kernel):

    black_image = Image.new('RGB', (w, h), (0, 0, 0))
    for i in range(9):
        black_image.putpixel((4, i), (255, 255, 255))
        black_image.putpixel((i, 4), (255, 255, 255))
    
    black_image.show(title="Black with White Cross")
    
    kernel_filter = ImageFilter.Kernel((3, 3), kernel, scale=sum(kernel) or 1)
    convolved_image = black_image.filter(kernel_filter)
    
    convolved_image.show(title="Black with White Cross Convolved")

    return (black_image, convolved_image)

def make_image_convolution_white(kernel):
    white_image = Image.new('RGB', (w, h), (255, 255, 255))
    for i in range(9):
        white_image.putpixel((4, i), (0, 0, 0))
        white_image.putpixel((i, 4), (0, 0, 0))
    
    white_image.show(title="White with Black Cross")
    
    kernel_filter = ImageFilter.Kernel((3, 3), kernel, scale=sum(kernel) or 1)
    convolved_image = white_image.filter(kernel_filter)
    
    convolved_image.show(title="White with Black Cross Convolved")

    return (white_image, convolved_image)



@cocotb.test()
async def test_convolution(dut):
    
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    dut.rst_in.value = 1 
    await ClockCycles(dut.clk_in, 10)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 10)

    for hcount in range(10):
        for vcount in range(10):

            dut.hcount_in.value = hcount
            dut.vcount_in.value = vcount
            dut.data_valid_in.value = 1
            dut.data_in.value = 0x5555_5555_5555
            await ClockCycles(dut.clk_in,1)

    await ClockCycles(dut.clk_in, 10)

def is_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "convolution.sv"]
    sources += [proj_path / "hdl" / "kernels.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="convolution",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="convolution",
        test_module="test_convolution",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()