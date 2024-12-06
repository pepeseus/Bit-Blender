`timescale 1ns / 1ps
`default_nettype none

module uart_debugger (
	input wire clk_25mhz,                 // 25mhz clock
  input wire rst_in,                    // system reset
	input wire [15:0] wave_width_in,      // UI switches
	input wire [15:0] debug_data_in,       // debug sample data
  output logic [15:0] debug_index_out,   // debug sample index requested
  output logic uart_tx;                 // UART TX wire
);

// TODO add potentiometer start index


always_ff @(posedge clk_25mhz) begin
  if (rst_in) begin
    debug_index_out <= 1'b0;
  end else begin
    
  end
end


endmodule

`default_nettype wire