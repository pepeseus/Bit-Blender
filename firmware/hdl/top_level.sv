`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
  //  output logic [15:0] led,
   // UART
   input wire          midi_rx,    // UART MIDI-FPGA
   output logic        uart_txd,   // UART FPGA-computer
   // I2S
   output wire          i2s_bclk,    // clock
   output wire          i2s_sd,    // data
   output wire          i2s_ws,    // channel select
   input wire [15:0]   sw,
   input wire [3:0]    btn,
   // RGB LEDs
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   // PMODS
   output logic pmoda4,
   output logic pmoda5,
   output logic pmoda6,
   output logic pmoda7,
   // Seven-segment display
  //  output logic [3:0]  ss0_an,     // Anode control for upper digits
  //  output logic [3:0]  ss1_an,     // Anode control for lower digits
  //  output logic [6:0]  ss0_c,      // Cathode controls for upper digits
  //  output logic [6:0]  ss1_c      // Cathode controls for lower digits
   // HDMI
  //  output logic [2:0]  hdmi_tx_p,  // HDMI output signals (positive)
  //  output logic [2:0]  hdmi_tx_n,  // HDMI output signals (negative)
  //  output logic        hdmi_clk_p, 
  //  output logic        hdmi_clk_n  // Differential HDMI clock

   // Debugging
   output logic [7:0] analyzer
   );

  localparam SAMPLE_WIDTH = 16;
  localparam NUM_OSCILLATORS = 4;
  localparam BRAM_DEPTH = 16214;               // temp memory depth     ~ $clog2(262141) = 18
  localparam WW_WIDTH = $clog2(BRAM_DEPTH);     // width of the wave width lol = 18 bits
  localparam MMEM_MAX_DEPTH = 1_000_000_000;    // main memory max depth ~ $clog2(1_000_000_000) = 30
  localparam WS_WIDTH = $clog2(MMEM_MAX_DEPTH); // width of the wave start address = 30 bits


  // Reset signal
  logic sys_rst;
  assign sys_rst = btn[0];

  // Turn off RGB LEDs
  assign rgb0 = 0;
  assign rgb1 = 0;




  /**
    UI Handling
  */
  logic                     ui_update_trig;
  logic [WW_WIDTH-1:0]      wave_width;
  logic [WS_WIDTH-1:0]  wave_start_addr;

  ui_handler #(.WW_WIDTH(WW_WIDTH), .WS_WIDTH(WS_WIDTH))
  ui_handle (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .sw_in(sw),
    .pot_in(0),                         // TODO: potentiometer
    .wave_start_out(wave_start_addr),
    .wave_width_out(wave_width),
    .update_trig_out(ui_update_trig)
  );


  /**
    MIDI Processing
  */

  // MIDI UART RX signal buffering
  logic midi_rx_buf0, midi_rx_buf1;
  always_ff @(posedge clk_100mhz) begin
    midi_rx_buf0 <= midi_rx;
    midi_rx_buf1 <= midi_rx_buf0;
  end

  // MIDI Reader
  logic [3:0] status;
  logic [7:0] data_byte1, data_byte2;
  logic valid_out_reader;

  midi_reader reader_main(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rx_wire_in(midi_rx_buf1),
    .status(status),
    .data_byte1(data_byte1),
    .data_byte2(data_byte2),
    .valid_out(valid_out_reader)
  );


  // MIDI Processor
  logic is_note_on;
  logic [23:0] playback_rate;
  logic valid_out_processor;

  midi_processor processor_main(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .status(status),
    .data_byte1(data_byte1),
    .data_byte2(data_byte2),
    .valid_in(valid_out_reader),
    .isNoteOn(is_note_on),
    .cycles_between_samples(playback_rate),
    .valid_out(valid_out_processor)
  );


  // Polyphonic MIDI Coordinator
  logic [NUM_OSCILLATORS-1:0] is_on;                            // track each oscillator
  logic [23:0] playback_rates [NUM_OSCILLATORS-1:0];            // corresponding notes for each oscillator
  logic [SAMPLE_WIDTH-1:0] stream;                              // output playback mixed sample

  // assign pmoda4 = stream[0];
  assign pmoda5 = is_note_on;
  assign pmoda6 = valid_out_processor;
  assign pmoda7 = playback_rates[3][0];

  midi_coordinator #(.NUM_OSCILLATORS(NUM_OSCILLATORS),
    .SAMPLE_WIDTH(SAMPLE_WIDTH)
  ) coordinator_main (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .isNoteOn(is_note_on),
    .cycles_between_samples(playback_rate),
    .valid_in(valid_out_processor),
    .is_on(is_on),
    .playback_rate(playback_rates),
    .out_samples(osc_samples),
    .stream_out(stream),
    .test(pmoda4)
  );

  

  /**
    Memory Management
  */

  logic [NUM_OSCILLATORS-1:0][WW_WIDTH-1:0]      osc_indices;   // playback sample index for each oscillator
  logic [NUM_OSCILLATORS-1:0][SAMPLE_WIDTH-1:0]  osc_samples;   // output sample data for each oscillator    // TODO OFF

  logic [WW_WIDTH-1:0]      viz_index;                           // hdmi pixel index
  logic [SAMPLE_WIDTH-1:0]  viz_sample;                          // output hdmi pixel data

  logic [WW_WIDTH-1:0]      debug_index;                         // debug sample index
  logic [SAMPLE_WIDTH-1:0]  debug_sample;                        // debug sample data

  wave_loader #(
    .NUM_OSCILLATORS(NUM_OSCILLATORS),    // number of oscillators
    .SAMPLE_WIDTH(SAMPLE_WIDTH),          // width of the sample data
    .BRAM_DEPTH(BRAM_DEPTH),              // depth of the DRAM
    .WW_WIDTH(WW_WIDTH),                  // width of the wave width
    .MMEM_MAX_DEPTH(MMEM_MAX_DEPTH)       // depth of the main memory
  )
  memio (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .wave_width_in(wave_width),
    .ui_update_trig_in(ui_update_trig),
    .osc_index_in(osc_indices),
    .osc_data_out(osc_samples),
    .viz_index_in(viz_index),
    .viz_data_out(viz_sample),
    .debug_index_in(debug_index),
    .debug_data_out(debug_sample),
    .analyzer(analyzer)
  );




  // temp:
  // assign is_on[0] = is_note_on;
  // assign playback_rates[0] = playback_rate;
  // assign stream = osc_samples[0];                   // TODO OFF

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
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .wave_width_in(wave_width),
        .is_on_in(is_on[i]),
        .playback_rate_in(playback_rates[i]),
        .sample_index_out(osc_indices[i])
        // .sample_data_out(osc_samples[i])
      );
    end
  endgenerate
  

  // I2S TX
  i2s_clk_wiz_44100 i2s_clk_wiz (     // I2S clock generator
    .rst(sys_rst),
    .clk_ref(clk_100mhz),
    .clk_bit(i2s_bclk),
    .clk_ws(i2s_ws)
  );

  i2s_tx #(                           // I2S transmitter        
    .WIDTH(SAMPLE_WIDTH)
  ) i2s_tx_inst (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .input_l_tdata(stream),
    .input_r_tdata(stream),
    .input_tvalid(1'b1),  // Valid signal always asserted
    .input_tready(),      // Unused
    .sck(i2s_bclk),
    .ws(i2s_ws),
    .sd(i2s_sd)             // TODO OFF
  );








  /**
    Visual View
  */




  /**
    Debugger
  */
  logic clk_25mhz;
  debug_clk_wiz_25mhz debug_clk_wiz (
    .rst(sys_rst),
    .clk_ref(clk_100mhz),
    .clk_25mhz(clk_25mhz)
  );

  uart_debugger debugger (
    .clk_25mhz(clk_25mhz),
    .rst_in(sys_rst),
    .wave_width_in(wave_width),
    .debug_data_in(debug_sample),
    .debug_index_out(debug_index),
    .uart_tx(uart_txd)
  );



  /**
    FFT View
  */



  /**
    Graph View
  */


  // debugging
  // assign pmodb[0] = stream[0];              // OFF
  // assign pmodb[1] = i2s_sd;                 // OFF
  // assign pmodb[2] = osc_samples[0][0];      // OFF
  // assign pmodb[3] = is_on[0];               // GOOD
  // assign pmodb[4] = playback_rates[0][0];   // ?? should be fine
  // assign pmodb[5] = osc_indices[0][0];      // GOOD
  // assign pmodb[0] = ui_update_trig;         // 
  // assign pmodb[1] = i2s_sd;                 // 
  // assign pmodb[2] = osc_samples[0][0];      // 
  // assign pmodb[3] = is_on[0];               // 
  // assign pmodb[4] = playback_rates[0][0];   // 
  // assign pmodb[5] = osc_indices[0][0];      // 



  // assign pmodb[0] = ui_update_trig;         // 
  // assign pmodb[1] = i2s_sd;                 // 
  // assign pmodb[2] = osc_samples[0][0];      // 
  // assign pmodb[3] = is_on[0];               // 
  // assign pmodb[4] = playback_rates[0][0];   // 
  // assign pmodb[5] = osc_indices[0][0];      // 



endmodule

`default_nettype wire
