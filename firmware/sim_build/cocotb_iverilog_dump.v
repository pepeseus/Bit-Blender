module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/artemolaptiev/Documents/projects/6.205/Bit-Blender/firmware/sim_build/wave_loader.fst");
    $dumpvars(0, wave_loader);
end
endmodule
