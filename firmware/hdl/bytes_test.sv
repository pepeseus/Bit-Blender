`timescale 1ns / 1ps
`default_nettype none

module bytes_test # (
  parameter WW_WIDTH = 18,
  parameter WS_WIDTH = 30,
  parameter SAMPLE_WIDTH = 16,
  parameter NUM_OSCILLATORS = 4,
  parameter BRAM_DEPTH = 26214,
  parameter MMEM_MAX_DEPTH = 1_000_000_000
)(
  input wire clk_in,
  input wire rst_in,
  input wire ui_update_trig,
  input wire [WW_WIDTH-1:0] wave_width,
  input wire is_note_on,
  input wire [23:0] playback_rate
  );

  /**
    Memory Management
  */

  logic [NUM_OSCILLATORS-1:0][WW_WIDTH-1:0]      osc_indices;   // playback sample index for each oscillator
  logic [NUM_OSCILLATORS-1:0][SAMPLE_WIDTH-1:0]  osc_samples;   // output sample data for each oscillator    // TODO OFF

  logic [WW_WIDTH-1:0]      viz_index;                           // hdmi pixel index
  logic [SAMPLE_WIDTH-1:0]  viz_sample;                          // output hdmi pixel data

  logic [WW_WIDTH-1:0]      bytes_screen_index;                  // debug sample index
  logic [SAMPLE_WIDTH-1:0]  bytes_screen_sample;                 // debug sample data

  wave_loader #(
    .NUM_OSCILLATORS(NUM_OSCILLATORS),    // number of oscillators
    .SAMPLE_WIDTH(SAMPLE_WIDTH),          // width of the sample data
    .BRAM_DEPTH(BRAM_DEPTH),              // depth of the DRAM
    .WW_WIDTH(WW_WIDTH),                  // width of the wave width
    .MMEM_MAX_DEPTH(MMEM_MAX_DEPTH)       // depth of the main memory
  )
  memio (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .wave_width_in(wave_width),
    .ui_update_trig_in(ui_update_trig),
    .osc_index_in(osc_indices),
    .osc_data_out(osc_samples),
    .viz_index_in(viz_index),
    .viz_data_out(viz_sample),
    .bytes_screen_index_in(bytes_screen_index),
    .bytes_screen_data_out(bytes_screen_sample)
  );


  logic [NUM_OSCILLATORS-1:0] is_on;                            // track each oscillator
  logic [23:0] playback_rates [NUM_OSCILLATORS-1:0];            // corresponding notes for each oscillator



  // temp:
  assign is_on[0] = is_note_on;
  assign playback_rates[0] = playback_rate;
  // assign stream = osc_samples[0];                  

  /**
    Audio Playback
  */
  // Oscillators
  generate
    genvar i;
    for (i = 0; i < NUM_OSCILLATORS; i++) begin
      oscillator
      #(.WW_WIDTH(WW_WIDTH)) 
      osc_inst (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .wave_width_in(wave_width),
        .is_on_in(is_on[i]),
        .playback_rate_in(playback_rates[i]),
        .sample_index_out(osc_indices[i])
      );
    end
  endgenerate
  

  /**
    Bytes Screen
  */
  logic uart_txd;

  bytes_screen bytes_screen (
    .clk_in(clk_in),
    .rst_in(rst_in | ui_update_trig),
    .wave_width_in(wave_width),
    .osc_indices(osc_indices),
    .bytes_screen_data_in(bytes_screen_sample),
    .bytes_screen_index_out(bytes_screen_index),
    .uart_txd(uart_txd)
  );

endmodule

`default_nettype wire
