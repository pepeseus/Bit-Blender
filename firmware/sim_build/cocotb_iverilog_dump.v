module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/artemolaptiev/Documents/projects/6.205/Bit-Blender/firmware/sim_build/bytes_test.fst");
    $dumpvars(0, bytes_test);
end
endmodule
