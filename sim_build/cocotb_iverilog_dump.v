module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/jesusrdiaz/Desktop/6.111/Bit-Blender/sim_build/wave_loader.fst");
    $dumpvars(0, wave_loader);
end
endmodule
