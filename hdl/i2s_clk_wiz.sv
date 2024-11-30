`timescale 1ns / 1ps
`default_nettype none

module i2s_clk_wiz_44100 #(
  parameter integer I2S_BCLK_NCYCLES = 24,
  parameter integer I2S_WS_NBITS = 24
)(
  // Status and control signals
  input  wire reset,
  input  wire clk_ref,
  // Clock out ports
  output reg clk_bit = 0,
  output reg clk_ws = 0
);

  reg [4:0] counter_bit = 0;
  reg [4:0] counter_ws = 0;

  always @(posedge clk_ref) begin
    if (reset) begin
      counter_bit <= 0;
      clk_bit <= 0;
      counter_ws <= 0;
      clk_ws <= 0;
    end else begin
      if (counter_bit == I2S_BCLK_NCYCLES - 1) begin
        counter_bit <= 0;
        clk_bit <= ~clk_bit;  // Toggle clk_bit

        if (clk_bit) begin  // Falling edge of clk_bit
          if (counter_ws == I2S_WS_NBITS - 1) begin
            counter_ws <= 0;
            clk_ws <= ~clk_ws;  // Toggle clk_ws
          end else begin
            counter_ws <= counter_ws + 1;
          end
        end
      end else begin
        counter_bit <= counter_bit + 1;
      end
    end
  end

endmodule
