`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
   output logic [15:0] led,
   // UART
   input wire          uart_rxd,   // UART computer-FPGA
  //  output logic        uart_txd,   // UART FPGA-computer
   // I2S
   output wire          i2s_bclk,    // clock
   output wire          i2s_sd,    // data
   output wire          i2s_ws,    // channel select
   input wire [15:0]   sw,
   input wire [3:0]    btn,
   // RGB LEDs
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   // Seven-segment display
   output logic [3:0]  ss0_an,     // Anode control for upper digits
   output logic [3:0]  ss1_an,     // Anode control for lower digits
   output logic [6:0]  ss0_c,      // Cathode controls for upper digits
   output logic [6:0]  ss1_c      // Cathode controls for lower digits
   // HDMI
  //  output logic [2:0]  hdmi_tx_p,  // HDMI output signals (positive)
  //  output logic [2:0]  hdmi_tx_n,  // HDMI output signals (negative)
  //  output logic        hdmi_clk_p, 
  //  output logic        hdmi_clk_n  // Differential HDMI clock
   );

  localparam AUDIO_WIDTH = 24;

  // Reset signal
  logic sys_rst;
  assign sys_rst = btn[0];

  // Turn off RGB LEDs
  assign rgb0 = 0;
  assign rgb1 = 0;

  // UART RX signal buffering
  logic uart_rx_buf0, uart_rx_buf1;
  always_ff @(posedge clk_100mhz) begin
    uart_rx_buf0 <= uart_rxd;
    uart_rx_buf1 <= uart_rx_buf0;
  end

  // MIDI Reader
  logic [3:0] status;
  logic [7:0] data_byte1, data_byte2;
  logic valid_out_reader;

  midi_reader reader_main(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rx_wire_in(uart_rx_buf1),
    .status(status),
    .data_byte1(data_byte1),
    .data_byte2(data_byte2),
    .valid_out(valid_out_reader)
  );

  // MIDI Processor
  logic is_note_on;
  logic [23:0] playback_rate;

  midi_processor processor_main(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .status(status),
    .data_byte1(data_byte1),
    .data_byte2(data_byte2),
    .valid_in(valid_out_reader),
    .isNoteOn(is_note_on),
    .cycles_between_samples(playback_rate)
  );

  // Oscillator
  logic [23:0] sample_data;

  oscillator osc_inst(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .is_on_in(is_note_on), // is_note_on
    .playback_rate_in(playback_rate),
    .sample_data_out(sample_data)
  );



  /**
    I2S TX
  */

  i2s_clk_wiz_44100 i2s_clk_wiz (
    .reset(sys_rst),
    .clk_ref(clk_100mhz),
    .clk_bit(i2s_bclk),
    .clk_ws(i2s_ws)
  );
  
  // I2S Transmitter
  i2s_tx #(
    .WIDTH(AUDIO_WIDTH)
  ) i2s_tx_inst (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .input_l_tdata(sample_data),
    .input_r_tdata(sample_data),
    .input_tvalid(1'b1),  // Valid signal always asserted
    .input_tready(),      // Unused
    .sck(i2s_bclk),
    .ws(i2s_ws),
    .sd(i2s_sd)
  );

endmodule

`default_nettype wire
