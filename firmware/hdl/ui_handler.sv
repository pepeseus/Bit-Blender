`timescale 1ns / 1ps
`default_nettype none

module ui_handler #(
  parameter WW_WIDTH = 18,      // width of the wave width
  parameter WS_WIDTH = 30       // width of the wave start address
)(
	input wire clk_in,            // system clock
  input wire rst_in,            // system reset
	input wire [15:0] sw_in,      // UI switches
  input wire [11:0] pot_in,     // potentiometer
  output logic [WS_WIDTH-1:0] wave_start_out,   // start address of the wave data
  output logic [WW_WIDTH-1:0] wave_width_out,   // width of the wave data
	output logic update_trig_out          // trigger detected UI update
);

logic [15:0] prev_sw_in;
logic [11:0] prev_pot_in;
logic prev_rst_in;

always_ff @(posedge clk_in) begin
  if (rst_in) begin
    update_trig_out <= 1'b0;
    prev_sw_in <= 16'b0;
    prev_pot_in <= 12'b0;
    wave_start_out <= 30'b0;
    wave_width_out <= 18'b0;
  end else begin

    // detect UI update (or initial update)
    if ((sw_in != prev_sw_in) | prev_rst_in) begin
      update_trig_out <= 1'b1;
      wave_start_out <= {pot_in[11:0], 18'b0};    // pot in times 2^18 TODO ?
      wave_width_out <= {sw_in[15:0], 2'b0};      // sw in times 2^2
    end else begin
      update_trig_out <= 1'b0;
    end

    // update previous values
    prev_sw_in <= sw_in;
    prev_pot_in <= pot_in;
  end

  // update prev reset value
  prev_rst_in <= rst_in;
end


endmodule

`default_nettype wire