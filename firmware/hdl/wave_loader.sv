`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
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
	input wire    [NUM_OSCILLATORS-1:0]                   osc_is_on_in,   // TODO do I need to return 0 if is_on_in is low?
	input wire    [NUM_OSCILLATORS-1:0][WW_WIDTH-1:0]     osc_index_in,   // playback sample index for each oscillator
	output logic  [NUM_OSCILLATORS-1:0][SAMPLE_WIDTH-1:0] osc_data_out,   // output sample data for each oscillator

  // Visual
	input wire    [WW_WIDTH-1:0]        viz_index_in,       // hdmi pixel index
	output logic  [SAMPLE_WIDTH-1:0]    viz_data_out,       // output hdmi pixel data

  // Debug
  input wire    [WW_WIDTH-1:0]        debug_index_in,     // debug sample index     
  output logic  [SAMPLE_WIDTH-1:0]    debug_data_out,      // debug sample data

  output logic pmod4,
  output logic pmod5,
  output logic pmod6,
  output logic pmod7,

  output logic [7:0] analyzer

);

// assign analyzer[0] = ui_update_trig_in;    // 
// assign analyzer[1] = writing;              // 
// assign analyzer[2] = incrementing;      //
// assign analyzer[7:3] = sample_index[4:0];      // 
assign analyzer[0] = writing;    // 
assign analyzer[7:1] = debug_data_out[6:0];      //
// assign analyzer[3] = sample_data[0];       // 
// assign analyzer[4] = osc_data_out[0][0];   // 
// assign analyzer[5] = osc_index_in[0][0];   // 


logic [WW_WIDTH-1:0] sample_index;            // index of the sample in the main memory // TODO replace with SD size
logic [SAMPLE_WIDTH-1:0] sample_data;         // output sample data from the main memory
logic writing;                                // enable writing to the BRAMs from the main memory
logic zero;                                   // for some fantastic reason, vivado freezes the build 
                                              // if zero isn't passed into main mem write port
logic [SAMPLE_WIDTH-1:0] curr_data_out;
logic [WW_WIDTH-1:0]     curr_oscillator_index;

logic incrementing;

int prev_ind;

assign prev_ind = (index == 0) ? (NUM_OSCILLATORS - 1) : index - 1;
assign pmod4 = osc_data_out[0][0];
assign pmod5 = osc_data_out[1][0];
assign pmod6 = index[0];
assign pmod7 = curr_oscillator_index[0];


always_ff @(posedge clk_in) begin
  if (rst_in) begin
    // reset all oscillators data
    // for (int i = 0; i < NUM_OSCILLATORS; i++) begin
    //   osc_data_out[i] <= 16'b0;
    // end
    // reset visual data
    // viz_data_out <= 16'b0;
    // reset debug data
    // debug_data_out <= 16'b0;

    // reset main memory data
    sample_index <= 18'b0;
    writing <= 1'b0;
    zero <= 1'b0;
    // curr_oscillator_index <= osc_index_in[0]; // TODO necessary??

    incrementing <= 1'b0;
  end else begin

    curr_oscillator_index <= osc_index_in[index];
    osc_data_out[prev_ind] <= curr_data_out;

    // start writing from the main memory
    if (ui_update_trig_in) begin
      sample_index <= 18'b0;
      writing <= 1'b1;
      incrementing <= 1'b0;
    end

    // continue writing until the wave width is reached
    else if (writing & (sample_index+1 < wave_width_in)) begin
      sample_index <= sample_index + 1;
      incrementing <= 1'b1;
    end else begin
      sample_index <= 18'b0;
      writing <= 1'b0;
      incrementing <= 1'b0;
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
  .INIT_FILE(`FPATH(sine.mem))
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
  .dinb(),                // Port B RAM input data, width determined from RAM_WIDTH
  .web(zero),             // Port B write enable      // TODO mistery zero is needed to avoid vivado freeze
  .enb(writing),          // Port B RAM Enable,
  .rstb(1'b0),            // Port B output reset
  .regceb(1'b1)           // Port B output register enable
);


/**
 * Oscillator BRAM
 */

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
  .addrb(curr_oscillator_index),  // Port B address bus,
  .doutb(curr_data_out),  // Port B RAM output data,
  .dinb(16'b0),             // Port B RAM input data, width determined from RAM_WIDTH
  .web(1'b0),               // Port B write enable
  // .enb(osc_is_on_in[i]),    // Port B RAM Enable,        // TODO is this returning 0 when not on??
  .enb(1'b1),    // Port B RAM Enable,        // TODO is this returning 0 when not on??
  .rstb(1'b0),              // Port B output reset       // TODO is this returning 0 when not on??
  .regceb(1'b1)             // Port B output register enable
);

logic [$clog2(NUM_OSCILLATORS - 1)-1:0]  index;

clk_counter #(
  .MAX_COUNT(NUM_OSCILLATORS - 1)
  ) oscillator_counter
  ( 
    .clk_in(clk_in),
    .rst_in(rst_in),
    .count_out(index)
  );


/**
 * Visual Select BRAM
 */

// xilinx_true_dual_port_read_first_1_clock_ram #(
//   .RAM_WIDTH(SAMPLE_WIDTH),
//   .RAM_DEPTH(BRAM_DEPTH),
//   .RAM_PERFORMANCE("HIGH_PERFORMANCE")
//   )
// visual_select_ram (
//   .clka(clk_in),     // Clock

//   //writing port:
//   .addra(sample_index),     // Port A address bus,
//   .dina(sample_data),       // Port A RAM input data
//   .douta(),                 // Port A RAM output data, width determined from RAM_WIDTH
//   .wea(writing),            // Port A write enable
//   .ena(writing),            // Port A RAM Enable
//   .rsta(1'b0),              // Port A output reset
//   .regcea(1'b1),            // Port A output register enable

//   //reading port:
//   .addrb(curr_oscillator_index),     // Port B address bus, // TODO viz_index_in
//   .doutb(viz_data_out),     // Port B RAM output data,
//   .dinb(16'b0),             // Port B RAM input data, width determined from RAM_WIDTH
//   .web(1'b0),               // Port B write enable
//   .enb(1'b1),               // Port B RAM Enable,         // TODO same, should I reset to 0 when not on?
//   .rstb(1'b0),              // Port B output reset
//   .regceb(1'b1)             // Port B output register enable
// );



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
  .dinb(16'b0),             // Port B RAM input data, width determined from RAM_WIDTH
  .web(1'b0),               // Port B write enable
  .enb(1'b1),               // Port B RAM Enable,
  .rstb(1'b0),              // Port B output reset
  .regceb(1'b1)             // Port B output register enable
);



endmodule

`default_nettype wire