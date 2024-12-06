`timescale 1ns / 1ps
`default_nettype none

module debug_clk_wiz_25mhz (
  // Status and control signals
  input  wire rst,
  input  wire clk_ref,
  // Clock out ports
  output logic clk_25mhz
);

  logic [1:0] counter;

  always @(posedge clk_ref) begin
    if (rst) begin
      counter <= 0;
      clk_25mhz <= 0;
    end else begin
      if (counter == 0) begin
        clk_25mhz <= ~clk_25mhz;  // Toggle clk_25mhz
      end
      
      counter <= counter + 1;
    end
  end

endmodule

`default_nettype wire