`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
   output logic [15:0] led,
   // UART vals
	 input wire 				 uart_rxd, // UART computer-FPGA
	 output logic 			 uart_txd // UART FPGA-computer

   inout wire          i2c_scl, // i2c inout clock
   inout wire          i2c_sda, // i2c inout data
   input wire [15:0]   sw,
   input wire [3:0]    btn,
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   // seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits
   // hdmi port
   output logic [2:0]  hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
   output logic [2:0]  hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
   output logic        hdmi_clk_p, hdmi_clk_n //differential hdmi clock

   // i2s
   output logic        i2s_bclk,  // bit clock
   output logic        i2s_ws,    // word select
   output logic        i2s_sd     // serial data
   );

  localparam AUDIO_WIDTH = 24;

  //have btnd control system reset
  logic sys_rst;
  assign sys_rst = btn[0];

  // shut up those RGBs
  assign rgb0 = 0;
  assign rgb1 = 0;


  /**
    UART RX
  */
  // pass your uart_rx data through a couple buffers,
  // save yourself the pain of metastability!
  logic uart_rx_buf0, uart_rx_buf1;

  always_ff @(posedge clk_100mhz) begin
    uart_rx_buf0 <= uart_rxd;
    uart_rx_buf1 <= uart_rx_buf0;
  end

  /**
    MIDI Reader
  */
  logic [3:0] status;
  logic [7:0] data_byte1;
  logic [7:0] data_byte2;
  logic valid_out_reader;

  midi_reader reader_main(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rx_wire_in(uart_rx_buf1),
    .status(status),
    .data_byte1(data_byte1),
    .data_byte2(data_byte2),
    .valid_out(valid_out_reader)
  )

  /**
    MIDI Processor
  */
  logic is_note_on;
  logic [23:0] playback_rate;

  midi_processor processor_main(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .status(status),
    .data_byte1(data_byte1),
    .data_byte2(data_byte2),
    .valid_out(valid_out_reader),
    .isNoteOn(is_note_on),
    .cycles_between_samples(playback_rate)
  )

  /**
    Oscillator
  */
  logic [23:0] sample_data;

  oscillator osc_inst (
    .clk_in(clk_100mhz),
    .rst_in(rst_in),
    .is_on_in(is_note_on),
    .playback_rate_in(playback_rate),
    .sample_data_out(sample_data)
  );



  /**
    I2S TX
  */

  // generate the I2S clock (TODO use proper wizard in future)
  i2s_clk_wiz_44100 i2s_clk_wiz (
    .reset(rst_in),
    .clk_ref(clk_in),
    .clk_bit(i2s_bclk),
    .clk_ws(i2s_ws)
  );

  // instantiate the I2S TX module
  i2s_tx #(
    .WIDTH(AUDIO_WIDTH)
  ) i2s_tx_inst (
    .clk(clk_100mhz),
    .rst(rst_in),
    .input_l_tdata(sample_data),  // same data for both channels
    .input_r_tdata(sample_data),
    .input_tvalid(1'b1),          // TODO is this ok?
    .input_tready(),              // TODO do we care?
    .sck(i2s_bclk),
    .ws(i2s_ws),
    .sd(i2s_sd)
  );
  


endmodule // top_level


`default_nettype wire

