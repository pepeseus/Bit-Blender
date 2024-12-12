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
  // output logic [3:0]  ss0_an,     // Anode control for upper digits
  // output logic [3:0]  ss1_an,     // Anode control for lower digits
  // output logic [6:0]  ss0_c,      // Cathode controls for upper digits
  // output logic [6:0]  ss1_c      // Cathode controls for lower digits
  // HDMI
  output logic [2:0]  hdmi_tx_p,  // HDMI output signals (positive)
  output logic [2:0]  hdmi_tx_n,  // HDMI output signals (negative)
  output logic        hdmi_clk_p, 
  output logic        hdmi_clk_n,  // Differential HDMI clock

  // SD Card
  inout wire [3:0] sd_dat,
  input wire sd_cd,
  output logic sd_sck, 
  output logic sd_cmd,

  // Debugging
  output logic [7:0] analyzer
  );

  localparam SAMPLE_WIDTH = 16;
  localparam NUM_OSCILLATORS = 4;
<<<<<<< HEAD
  localparam BRAM_DEPTH = 30214;                    // temp memory depth     ~ $clog2(262141) = 18
  localparam SAMPLES_PER_BRAM = BRAM_DEPTH * 512 / SAMPLE_WIDTH;
  localparam WW_WIDTH = $clog2(SAMPLES_PER_BRAM);   // width of the wave width lol = 18 bits
  localparam MMEM_MAX_DEPTH = 1_000_000_000;        // main memory max depth ~ $clog2(1_000_000_000) = 30
  localparam WS_WIDTH = $clog2(MMEM_MAX_DEPTH);     // width of the wave start address = 30 bits
=======
  localparam BRAM_DEPTH = 10214;               // temp memory depth     ~ $clog2(262141) = 18
  localparam WW_WIDTH = $clog2(BRAM_DEPTH);     // width of the wave width lol = 18 bits
  localparam MMEM_MAX_DEPTH = 1_000_000_000;    // main memory max depth ~ $clog2(1_000_000_000) = 30
  localparam WS_WIDTH = $clog2(MMEM_MAX_DEPTH); // width of the wave start address = 30 bits
>>>>>>> 2fa23e7 (works)
  localparam PRE_DIVISION_AUDIO_SIZE = 32;


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
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst),
    .sw_in(sw),
    .pot_in(0),                         // TODO: potentiometer
    .sd_cd(sd_cd),
    .wave_start_out(wave_start_addr),
    .wave_width_out(wave_width),
    .update_trig_out(ui_update_trig)
  );


  /**
    MIDI Processing
  */

  // MIDI UART RX signal buffering
  logic midi_rx_buf0, midi_rx_buf1;
  always_ff @(posedge clk_100_passthrough) begin
    midi_rx_buf0 <= midi_rx;
    midi_rx_buf1 <= midi_rx_buf0;
  end

  // MIDI Reader
  logic [3:0] status;
  logic [7:0] data_byte1, data_byte2;
  logic valid_out_reader;

  midi_reader reader_main(
    .clk_in(clk_100_passthrough),
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
    .clk_in(clk_100_passthrough),
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
  logic [PRE_DIVISION_AUDIO_SIZE-1:0] pre_division_stream;                              // pre division playback mixed sample
  logic has_updated;

  // assign pmoda4 = stream[0];
  assign pmoda5 = is_note_on;
  assign pmoda6 = valid_out_processor;
  assign pmoda7 = playback_rates[3][0];


  midi_coordinator #(.NUM_OSCILLATORS(NUM_OSCILLATORS),
    .SAMPLE_WIDTH(SAMPLE_WIDTH),
    .PRE_DIVISION_AUDIO_SIZE(PRE_DIVISION_AUDIO_SIZE)
  ) coordinator_main (
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst),
    .isNoteOn(is_note_on),
    .cycles_between_samples(playback_rate),
    .valid_in(valid_out_processor),
    .is_on(is_on),
    .playback_rate(playback_rates),
    .out_samples(osc_samples),
    .stream_out(pre_division_stream),
    .has_updated(has_updated)
  );

  logic [SAMPLE_WIDTH-1:0] stream;                              // output playback mixed sample
  // assign stream = pre_division_stream[SAMPLE_WIDTH-1:0];

  /**
    Output Divider
  */
  output_divider #(.NUM_OSCILLATORS(NUM_OSCILLATORS),
    .SAMPLE_WIDTH(SAMPLE_WIDTH),
    .PRE_DIVISION_AUDIO_SIZE(PRE_DIVISION_AUDIO_SIZE)
  ) divider_main (
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst),
    .stream_in(pre_division_stream),
    .is_on(is_on),
    .has_updated(has_updated),
    .stream_out(stream)
  );
  

  /**
    Memory Management
  */

  logic [NUM_OSCILLATORS-1:0][WW_WIDTH-1:0]      osc_indices;   // playback sample index for each oscillator
  logic [NUM_OSCILLATORS-1:0][SAMPLE_WIDTH-1:0]  osc_samples;   // output sample data for each oscillator  

  logic [WW_WIDTH-1:0]      viz_index;                           // hdmi pixel index
  logic [SAMPLE_WIDTH-1:0]  viz_sample;                          // output hdmi pixel data

<<<<<<< HEAD
=======

>>>>>>> 2fa23e7 (works)
  logic [WW_WIDTH-1:0]      bytes_screen_index;                  // debug sample index
  logic [SAMPLE_WIDTH-1:0]  bytes_screen_sample;                 // debug sample data
  logic                     bytes_screen_sample_ready;           // debug sample data ready

  wave_loader #(
    .NUM_OSCILLATORS(NUM_OSCILLATORS),    // number of oscillators
    .SAMPLE_WIDTH(SAMPLE_WIDTH),          // width of the sample data
    .BRAM_DEPTH(BRAM_DEPTH),              // depth of the DRAM
    .SAMPLES_PER_BRAM(SAMPLES_PER_BRAM),  // number of samples per BRAM
    .WW_WIDTH(WW_WIDTH),                  // width of the wave width
    .MMEM_MAX_DEPTH(MMEM_MAX_DEPTH)       // depth of the main memory
  )
  memio (
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst),
    .wave_width_in(wave_width),
    .ui_update_trig_in(ui_update_trig),

    .osc_index_in(osc_indices),
    .osc_data_out(osc_samples),
    .viz_index_in(viz_index),
    .viz_data_out(viz_sample),
<<<<<<< HEAD
    .bytes_screen_index_in(bytes_screen_index),
    .bytes_screen_data_out(bytes_screen_sample),
    .bytes_screen_data_ready(bytes_screen_sample_ready),

    .sd_dat(sd_dat),
    .sd_cd(sd_cd),
    .sd_sck(sd_sck),
    .sd_cmd(sd_cmd)
=======

    // .debug_index_in(debug_index),
    // .debug_data_out(debug_sample),
    .analyzer(analyzer),

    .bytes_screen_index_in(bytes_screen_index),
    .bytes_screen_data_out(bytes_screen_sample),
    .bytes_screen_data_ready(bytes_screen_sample_ready)

    // .sd_dat(sd_dat),
    // .sd_cd(sd_cd),
    // .sd_sck(sd_sck),
    // .sd_cmd(sd_cmd)
>>>>>>> 2fa23e7 (works)
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
        .clk_in(clk_100_passthrough),
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
    .clk_ref(clk_100_passthrough),
    .clk_bit(i2s_bclk),
    .clk_ws(i2s_ws)
  );

  i2s_tx #(                           // I2S transmitter        
    .WIDTH(SAMPLE_WIDTH)
  ) i2s_tx_inst (
    .clk(clk_100_passthrough),
    .rst(sys_rst),
    .input_l_tdata(stream),
    .input_r_tdata(stream),
    .input_tvalid(1'b1),  // Valid signal always asserted
    .input_tready(),      // Unused
    .sck(i2s_bclk),
    .ws(i2s_ws),
    .sd(i2s_sd)            
  );








  /**
    Visual View
  */

  logic          clk_pixel;
  logic          clk_5x;
  logic          clk_100_passthrough;
  logic [7:0] red, green, blue; //red green and blue pixel values for output


  clk_wiz_0_clk_wiz wizard_hdmi
    (.clk_in1(clk_100mhz),
     .clk_tmds(clk_5x),
     .clk_pixel(clk_pixel),
     .clk_100_pass(clk_100_passthrough),
     .reset(0));

  logic [10:0] hcount; //hcount of system!
  logic [9:0] vcount; //vcount of system!
  logic hor_sync; //horizontal sync signal
  logic vert_sync; //vertical sync signal
  logic active_draw; //ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; //one cycle active indicator of new frame of info!
  logic [5:0] frame_count; //0 to 59 then rollover frame counter

  //default instantiation so making signals for 720p
  video_sig_gen mvg(
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));

  assign red = osc_samples[0];
  assign green = osc_samples[1];
  assign blue = osc_samples[2];
    // assign red = 8'h00;
    // assign green = 8'hFF;
    // assign blue = 8'h1F;

  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
 
  //three tmds_encoders (blue, green, red)
  //note green should have no control signal like red
  //the blue channel DOES carry the two sync signals:
  //  * control_in[0] = horizontal sync signal
  //  * control_in[1] = vertical sync signal
 
  tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(red),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(green),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(blue),
      .control_in({vert_sync, hor_sync}),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[0]));
 
  //three tmds_serializers (blue, green, red):

  tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));
 
  //output buffers generating differential signals:
  //three for the r,g,b signals and one that is at the pixel clock rate
  //the HDMI receivers use recover logic coupled with the control signals asserted
  //during blanking and sync periods to synchronize their faster bit clocks off
  //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
  //the slower 74.25 MHz clock)
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));


  /**
    Debugger
  */
  bytes_screen bytes_screen (
    .clk_in(clk_100_passthrough),
    .rst_in(sys_rst | ui_update_trig),
    .wave_width_in(wave_width),
    .osc_indices(osc_indices),
    .bytes_screen_data_ready(bytes_screen_sample_ready),
    .bytes_screen_data_in(bytes_screen_sample),
    .bytes_screen_index_out(bytes_screen_index),
    .uart_txd(uart_txd),
    .analyzer(analyzer)
  );



  /**
    FFT View
  */



  /**
    Graph View
  */




endmodule

`default_nettype wire
