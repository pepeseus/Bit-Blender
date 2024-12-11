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
  parameter SAMPLES_PER_BRAM,       // number of samples per BRAM (wave width max length)
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
	input wire    [WW_WIDTH-1:0]        viz_index_in,               // hdmi pixel index
	output logic  [SAMPLE_WIDTH-1:0]    viz_data_out,               // output hdmi pixel data

  // Debug
  input wire    [WW_WIDTH-1:0]        bytes_screen_index_in,      // debug sample index     
  output logic  [SAMPLE_WIDTH-1:0]    bytes_screen_data_out,      // debug sample data
  output logic                        bytes_screen_data_ready,    // debug sample data ready

  // SD
  inout wire    [3:0]                 sd_dat,                     // data from the SD card
  input wire                          sd_cd,                      // card detect
  output logic                        sd_sck,                     // clock to the SD card
  output logic                        sd_cmd                      // command to the SD card
);


// Choosing who to serve from the BRAM
logic [SAMPLE_WIDTH-1:0] curr_data_out;
logic [WW_WIDTH-1:0]     curr_oscillator_index;

int prev_ind;
assign prev_ind = (index == 0) ? (NUM_OSCILLATORS - 1) : index - 1;

always_ff @(posedge clk_in) begin
  if (rst_in) begin
    // curr_oscillator_index <= osc_index_in[0]; // TODO necessary??
  end else begin
    curr_oscillator_index <= osc_index_in[index];
    osc_data_out[prev_ind] <= curr_data_out;
  end
end





// Writing from the Main Mem to BRAMs
// logic [WW_WIDTH-1:0] sample_index;            // index of the sample in the main memory // TODO replace with SD size
// logic [SAMPLE_WIDTH-1:0] sample_data;         // output sample data from the main memory
// logic writing;                                // enable writing to the BRAMs from the main memory

// always_ff @(posedge clk_in) begin
//   if (rst_in) begin
//     // reset main memory data
//     sample_index <= 18'b0;
//     writing <= 1'b0;

//   end else begin
//     // start writing from the main memory
//     if (ui_update_trig_in) begin
//       sample_index <= 18'b0;
//       writing <= 1'b1;
//     end

//     // continue writing until the wave width is reached
//     else if (writing & (sample_index+1 < wave_width_in)) begin
//       sample_index <= sample_index + 1;
//     end else begin
//       sample_index <= 18'b0;
//       writing <= 1'b0;
//     end
    
//   end
// end



// typedef enum { IDLE, READ_SD_CHUNK1, READ_SD_CHUNK2, WRITE_BRAM } state_t;
// state_t       memio_state;

// logic [511:0]       sd_line;
// logic [8:0]         inline_index;
// logic [6:0]         bytes_received_idx;
// logic [8:0]         offset;

// always_ff @(posedge clk_in) begin
//   if (rst_in) begin
//     sd_line <= 512'b0;
//     inline_index <= 9'b0;
//     bytes_received_idx <= 9'b0;
//     sd_rd <= 1'b0;

//     memio_state <= IDLE;
//   end else begin
//     // start writing from the main memory
//     if (ui_update_trig_in) begin
//       sample_index <= 18'b0;
//       sd_line <= 512'b0;
//       inline_index <= 9'b0;
//       // sd addr
//       sd_rd <= 1'b1;              // start reading from the SD card

//       memio_state <= READ_SD;
//     end

//     case(memio_state):
//       IDLE: begin
//         writing <= 1'b0;
//       end

//       READ_SD_CHUNK1: begin
//         if (sd_byte_available) begin
//           sd_line <= sd_line | (sd_dout << inline_index);  // TODO account for offset
//           inline_index <= inline_index + 8; // next byte

//           // first line is fully read
//           if (inline_index == 504) begin
//             sd_line <= sd_line << offset;
//             inline_index <= 0;

//             memio_state <= READ_SD_CHUNK2;
//           end
//         end
//       end

//       READ_SD_CHUNK2: begin
//         if (sd_byte_available) begin
//           sd_line <= sd_line | (sd_dout << inline_index);  // TODO account for offset
//           inline_index <= inline_index + 8; // next byte

//           // reached the offset
//           if (inline_index == offset) begin
//             memio_state <= WRITE_BRAM;
//           end
//         end
//       end

//       WRITE_BRAM: begin
//         // write to the BRAM
//         writing <= 1'b1;
//         line_index <= 0;   // TODO
//       end


//     endcase
//   end
// end


/**
 * Main Memory (SD Card)
 */
  
// generate 25 mhz clock for sd_controller 
// logic clk_25mhz;
// clk_wiz_25mhz (.rst(rst_in), .clk_100mhz(clk_in), .clk_25mhz(clk_25mhz));

// // sd_controller inputs
// logic sd_rd;                  // read enable
// logic [31:0] sd_addr;         // starting address for read/write operation

// assign sd_addr = 0;

// // sd_controller outputs
// logic sd_ready;                // high when ready for new read/write operation
// logic [7:0] sd_dout;           // data from sd card
// logic sd_byte_available;       // high when byte available for read

// sd_controller sd(
//   .reset(rst_in), 
//   .clk(clk_25mhz), 
//   .cs(sd_dat[3]), 
//   .mosi(sd_cmd), 
//   .miso(sd_dat[0]),                               
//   .sclk(sd_sck),                                  
//   .ready(sd_ready),                               // high when ready for new read/write operation
//   .address(sd_addr),                              // starting address for read/write operation (must be divisible by 512)
//   .rd(sd_rd),                                     // read enable      
//   .dout(sd_dout),                                 // read data from sd card
//   .byte_available(sd_byte_available),             // high when byte available for read
//   .wr(1'b0),                                      // write enable
//   .din(),                                         // write data to sd card
//   .ready_for_next_byte());                        // high when ready for new byte to be written

// xilinx_true_dual_port_read_first_1_clock_ram #(
//   .RAM_WIDTH(SAMPLE_WIDTH),
//   .RAM_DEPTH(BRAM_DEPTH),
//   .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
//   .INIT_FILE(`FPATH(sine.mem))
//   ) 
// main_ram (
//   .clka(clk_in),     // Clock

//   //writing port:
//   .addra(),               // Port A address bus,
//   .dina(),                // Port A RAM input data
//   .douta(),               // Port A RAM output data, width determined from RAM_WIDTH
//   .wea(1'b0),             // Port A write enable
//   .ena(1'b0),             // Port A RAM Enable (DISABLED)
//   .rsta(1'b0),            // Port A output reset
//   .regcea(1'b1),          // Port A output register enable

//   //reading port:
//   .addrb(sample_index),   // Port B address bus,
//   .doutb(sample_data),    // Port B RAM output data,
//   .dinb(),                // Port B RAM input data, width determined from RAM_WIDTH
//   .web(zero),             // Port B write enable      // TODO mistery zero is needed to avoid vivado freeze
//   .enb(writing),          // Port B RAM Enable,
//   .rstb(1'b0),            // Port B output reset
//   .regceb(1'b1)           // Port B output register enable
// );


/**
 * Oscillator BRAM
 */

// xilinx_true_dual_port_read_first_1_clock_ram #(
//   .RAM_WIDTH(SAMPLE_WIDTH),
//   .RAM_DEPTH(BRAM_DEPTH),
//   .RAM_PERFORMANCE("HIGH_PERFORMANCE")
//   ) 
// oscillator_ram (
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
//   .addrb(curr_oscillator_index),  // Port B address bus,
//   .doutb(curr_data_out),  // Port B RAM output data,
//   .dinb(16'b0),             // Port B RAM input data, width determined from RAM_WIDTH
//   .web(1'b0),               // Port B write enable
//   // .enb(osc_is_on_in[i]),    // Port B RAM Enable,        // TODO is this returning 0 when not on??
//   .enb(1'b1),    // Port B RAM Enable,        // TODO is this returning 0 when not on??
//   .rstb(1'b0),              // Port B output reset       // TODO is this returning 0 when not on??
//   .regceb(1'b1)             // Port B output register enable
// );

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
  * Bytes Screen BRAM
  */

logic [511:0]                         bram_line;
logic [$clog2(BRAM_DEPTH)-1:0]        bram_line_ind;      
logic [6:0]                           sample_select_ind;

logic [SAMPLE_WIDTH-1:0]              sample_data_out;
logic [WW_WIDTH-1:0]                  sample_index_in;

assign bram_line_ind = sample_index_in >> 6;  // sample_ind / SAMPLES_PER_LINE = sample_ind >> $clog2(SAMPLES_PER_LINE-1)
assign sample_select_ind = (sample_index_in & 6'b111111);

assign sample_data_out = bram_line[((63-sample_select_ind)<<4) +: 16];
// assign sample_data_out = bram_line >> (63 - sample_select_ind << 4);
// assign sample_data_out = bram_line >> (63 - sample_select_ind << 4);
// assign sample_data_out = bram_line[(sample_select_ind+1)*SAMPLE_WIDTH-1 -: SAMPLE_WIDTH];


assign sample_index_in = bytes_screen_index_in;
assign bytes_screen_data_out = sample_data_out;


xilinx_true_dual_port_read_first_1_clock_ram #(
  .RAM_WIDTH(512),
  .RAM_DEPTH(BRAM_DEPTH),
  .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
  .INIT_FILE(`FPATH(hello_world.mem))
  )
bytes_screen_ram (
  .clka(clk_in),     // Clock

  // //writing port:
  // .addra(sample_index),     // Port A address bus,
  // .dina(sd_line),           // Port A RAM input data
  // .douta(),                 // Port A RAM output data, width determined from RAM_WIDTH
  // .wea(writing),            // Port A write enable
  // .ena(writing),            // Port A RAM Enable
  // .rsta(1'b0),              // Port A output reset
  // .regcea(1'b1),            // Port A output register enable

  //writing port:
  .addra(),               // Port A address bus,
  .dina(),                // Port A RAM input data
  .douta(),               // Port A RAM output data, width determined from RAM_WIDTH
  .wea(1'b0),             // Port A write enable
  .ena(1'b0),             // Port A RAM Enable (DISABLED)
  .rsta(1'b0),            // Port A output reset
  .regcea(1'b1),          // Port A output register enable

  //reading port:
  .addrb(bram_line_ind),            // Port B address bus,    // HACK to reset the output after writing
  .doutb(bram_line),                // Port B RAM output data,
  .dinb(16'b0),                     // Port B RAM input data, width determined from RAM_WIDTH
  .web(1'b0),                       // Port B write enable
  .enb(1'b1),                       // Port B RAM Enable,
  .rstb(1'b0),                      // Port B output reset
  .regceb(1'b1)                     // Port B output register enable
);



endmodule

`default_nettype wire