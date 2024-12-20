`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module wave_loader #(
  parameter NUM_OSCILLATORS,        // number of oscillators
  parameter SAMPLE_WIDTH,           // width of the sample data
  parameter BRAM_DEPTH,             // depth of the BRAM
  parameter WW_WIDTH,               // width of the wave width
  parameter MMEM_MAX_DEPTH          // max depth of the main memory
  )(
	input wire    clk_in,    // system clock
  input wire    rst_in,    // system reset

  // UI
  input wire    [WW_WIDTH-1:0] wave_width_in,               // (UI switches) width of the wave data
  input wire    ui_update_trig_in,                          // trigger detected UI update

  // Audio
	input wire    [NUM_OSCILLATORS-1:0] osc_is_on_in,                         // TODO do I need to return 0 if is_on_in is low?
	input wire    [WW_WIDTH-1:0]        osc_index_in [NUM_OSCILLATORS-1:0],   // playback sample index for each oscillator
	output logic  [SAMPLE_WIDTH-1:0]    osc_data_out [NUM_OSCILLATORS-1:0],   // output sample data for each oscillator

  // Visual
	input wire    [WW_WIDTH-1:0]        viz_index_in,       // hdmi pixel index
	output logic  [SAMPLE_WIDTH-1:0]    viz_data_out,       // output hdmi pixel data

  // Debug
  input wire    [WW_WIDTH-1:0]        debug_index_in,     // debug sample index     
  output logic  [SAMPLE_WIDTH-1:0]    debug_data_out      // debug sample data
);


logic [WW_WIDTH-1:0] sample_index;            // index of the sample in the main memory // TODO replace with SD size
logic [SAMPLE_WIDTH-1:0] sample_data;         // output sample data from the main memory
logic writing;                                // enable writing to the main memory


always_ff @(posedge clk_in) begin
  if (rst_in) begin
    // reset all oscillators data
    for (int i = 0; i < NUM_OSCILLATORS; i++) begin
      osc_data_out[i] <= 16'b0;
    end
    // reset visual data
    viz_data_out <= 16'b0;

    // reset main memory data
    sample_index <= 18'b0;
    writing <= 1'b0;
  end else begin

    // start writing from the main memory
    if (ui_update_trig_in) begin
      sample_index <= 18'b0;
      writing <= 1'b1;
    end

    // continue writing until the wave width is reached
    if (sample_index+1 < wave_width_in) begin
      sample_index <= sample_index + 1;
    end else begin
      sample_index <= 18'b0;
      writing <= 1'b0;
    end
    
  end
end


/**
 * Main Memory
 */

xilinx_true_dual_port_read_first_1_clock_ram #(
  .RAM_WIDTH(SAMPLE_WIDTH),
  .RAM_DEPTH(BRAM_DEPTH),
  .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
  .INIT_FILE(`FPATH(track.mem))
  ) 
main_ram (
  .clka(clk_in),     // Clock

  //writing port:
  .addra(),               // Port A address bus,
  .dina(),                // Port A RAM input data
  .douta(),               // Port A RAM output data, width determined from RAM_WIDTH
  .wea(1'b0),             // Port A write enable
  .ena(1'b0),             // Port A RAM Enable (DISABLED)
  .rsta(1'b0),            // Port A output reset
  .regcea(1'b1),          // Port A output register enable

  //reading port:
  .addrb(sample_index),   // Port B address bus,
  .doutb(sample_data),    // Port B RAM output data,
  .dinb(1'b0),            // Port B RAM input data, width determined from RAM_WIDTH
  .web(writing),          // Port B write enable
  .enb(writing),          // Port B RAM Enable,
  .rstb(1'b0),            // Port B output reset
  .regceb(1'b1)           // Port B output register enable
);


/**
 * Oscillator BRAMs
 */

generate
  genvar i;
  for (i = 0; i < NUM_OSCILLATORS; i++) begin : osc_gen
    xilinx_true_dual_port_read_first_1_clock_ram #(
      .RAM_WIDTH(SAMPLE_WIDTH),
      .RAM_DEPTH(BRAM_DEPTH),
      .RAM_PERFORMANCE("HIGH_PERFORMANCE")
      ) 
    oscillator_ram (
      .clka(clk_in),     // Clock

      //writing port:
      .addra(sample_index),     // Port A address bus,
      .dina(sample_data),       // Port A RAM input data
      .douta(),                 // Port A RAM output data, width determined from RAM_WIDTH
      .wea(writing),            // Port A write enable
      .ena(writing),            // Port A RAM Enable
      .rsta(1'b0),              // Port A output reset
      .regcea(1'b1),            // Port A output register enable

      //reading port:
      .addrb(osc_index_in[i]),  // Port B address bus,
      .doutb(osc_data_out[i]),  // Port B RAM output data,
      .dinb(1'b0),              // Port B RAM input data, width determined from RAM_WIDTH
      .web(1'b0),               // Port B write enable
      .enb(osc_is_on_in[i]),    // Port B RAM Enable,        // TODO is this returning 0 when not on??
      .rstb(1'b0),              // Port B output reset       // TODO is this returning 0 when not on??
      .regceb(1'b1)             // Port B output register enable
    );
  end
endgenerate


/**
 * Visual Select BRAM
 */

xilinx_true_dual_port_read_first_1_clock_ram #(
  .RAM_WIDTH(SAMPLE_WIDTH),
  .RAM_DEPTH(BRAM_DEPTH),
  .RAM_PERFORMANCE("HIGH_PERFORMANCE")
  )
visual_select_ram (
  .clka(clk_in),     // Clock

  //writing port:
  .addra(sample_index),     // Port A address bus,
  .dina(sample_data),       // Port A RAM input data
  .douta(),                 // Port A RAM output data, width determined from RAM_WIDTH
  .wea(writing),            // Port A write enable
  .ena(writing),            // Port A RAM Enable
  .rsta(1'b0),              // Port A output reset
  .regcea(1'b1),            // Port A output register enable

  //reading port:
  .addrb(viz_index_in),     // Port B address bus,
  .doutb(viz_data_out),     // Port B RAM output data,
  .dinb(1'b0),              // Port B RAM input data, width determined from RAM_WIDTH
  .web(1'b0),               // Port B write enable
  .enb(1'b1),               // Port B RAM Enable,         // TODO same, should I reset to 0 when not on?
  .rstb(1'b0),              // Port B output reset
  .regceb(1'b1)             // Port B output register enable
);



/**
  * Debug BRAM
  */

xilinx_true_dual_port_read_first_1_clock_ram #(
  .RAM_WIDTH(SAMPLE_WIDTH),
  .RAM_DEPTH(BRAM_DEPTH),
  .RAM_PERFORMANCE("HIGH_PERFORMANCE")
  )
debug_ram (
  .clka(clk_in),     // Clock

  //writing port:
  .addra(sample_index),     // Port A address bus,
  .dina(sample_data),       // Port A RAM input data
  .douta(),                 // Port A RAM output data, width determined from RAM_WIDTH
  .wea(writing),            // Port A write enable
  .ena(writing),            // Port A RAM Enable
  .rsta(1'b0),              // Port A output reset
  .regcea(1'b1),            // Port A output register enable

  //reading port:
  .addrb(debug_index_in),   // Port B address bus,
  .doutb(debug_data_out),   // Port B RAM output data,
  .dinb(1'b0),              // Port B RAM input data, width determined from RAM_WIDTH
  .web(1'b0),               // Port B write enable
  .enb(1'b1),               // Port B RAM Enable,
  .rstb(1'b0),              // Port B output reset
  .regceb(1'b1)             // Port B output register enable
);



endmodule

`default_nettype wire