`timescale 1ns / 1ps
`default_nettype none

module ui_handler (
	input wire clk_in,            // system clock
  input wire rst_in,            // system reset
	input wire [15:0] sw_in,      // UI switches
	output logic update_trig_out  // trigger detected UI update
);



always_ff @(posedge clk_in) begin
  if (rst_in) begin
    update_trig_out <= 1'b0;
  end else begin
    
  end
end


endmodule

`default_nettype wire