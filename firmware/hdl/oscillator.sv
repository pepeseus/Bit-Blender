// `timescale 1ns / 1ps
// `default_nettype none

// `ifdef SYNTHESIS
// `define FPATH(X) `"X`"
// `else /* ! SYNTHESIS */
// `define FPATH(X) `"../../data/X`"
// `endif  /* ! SYNTHESIS */

// module oscillator (
// 	input wire clk_in,    // system clock
//   input wire rst_in,    // system reset
// 	input wire is_on_in,                 // 
// 	input wire [23:0] playback_rate_in,  // playback interval in clk cycles per sample
// 	output logic [15:0] sample_data_out
// );



// // playback
// /**
//   NOTE: In this form, the playback counter resets everytime is_on_in goes low. 
//   It immedeately cuts off the data output, and resets the sample index.

//   NOTE: The sample index naturally wraps around to 0 after 512 samples.
// */
// logic [8:0] sample_index;       // index of the sample in the waveform
// logic [23:0] playback_counter;

// always_ff @(posedge clk_in) begin
//   if (rst_in) begin
//     playback_counter <= 24'b0;
//     sample_index <= 9'b0;
//   end else begin
//     // is_on_in is high
//     if (is_on_in) begin
//       // hit playback rate interval, output next sample 
//       if (playback_counter >= playback_rate_in) begin
//         playback_counter <= 24'b0;

//         // increment the sample index
//         sample_index <= sample_index + 1;
//       end 

//       // otw, keep counting
//       else begin
//         playback_counter <= playback_counter + 1;
//       end

//     // is_on_in is low, reset the playback counter and sample index
//     end else begin
//       playback_counter <= 24'b0;
//       sample_index <= 9'b0;
//     end
//   end
// end


// // playback (alternative implementation)
// /**
//   NOTE: In this form, the playback counter does not reset when is_on_in goes low. 
//   It continues to output the wave until the sample index wraps back around to 0.

//   NOTE: The sample index naturally wraps around to 0 after 512 samples.
// */

// always_ff @(posedge clk_in) begin
//   if (rst_in) begin
//     playback_counter <= 24'b0;
//     sample_index <= 9'b0;
//   end else begin
//     // is_on_in is low & we're at the end of the sample, stop playback
//     if (~is_on_in & sample_index == 9'b0) begin
//       playback_counter <= 24'b0;
//     end

//     // is_on_in is high (or it's low, but we still finish the sample)
//     else begin
//       // hit playback rate interval, output next sample 
//       if (playback_counter >= playback_rate_in) begin
//         playback_counter <= 24'b0;

//         // increment the sample index
//         sample_index <= sample_index + 1;
//       end 

//       // otw, keep counting
//       else begin
//         playback_counter <= playback_counter + 1;
//       end
//     end
//   end
// end




// data

// xilinx_true_dual_port_read_first_1_clock_ram #(
//   .RAM_WIDTH(16),
//   .RAM_DEPTH(512),
//   .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
//   .INIT_FILE(`FPATH(sine.mem))
//   ) 
// waveform_ram (
//   .clka(clk_in),     // Clock

//   //writing port:
//   .addra(),     // Port A address bus,
//   .dina(),      // Port A RAM input data
//   .douta(),     // Port A RAM output data, width determined from RAM_WIDTH
//   .wea(1'b0),   // Port A write enable
//   .ena(1'b0),   // Port A RAM Enable (DISABLED)
//   .rsta(1'b0),      // Port A output reset
//   .regcea(1'b1),    // Port A output register enable

//   //reading port:
//   .addrb(sample_index),       // Port B address bus,
//   .doutb(sample_data_out),    // Port B RAM output data,
//   .dinb(1'b0),                // Port B RAM input data, width determined from RAM_WIDTH
//   .web(1'b0),                 // Port B write enable
//   .enb(1'b1),       // Port B RAM Enable,
//   .rstb(1'b0),      // Port B output reset
//   .regceb(1'b1)     // Port B output register enable
// );




// endmodule



`timescale 1ns / 1ps
`default_nettype none

module oscillator #(parameter WW_WIDTH) (
	input wire clk_in,    // system clock
  input wire rst_in,    // system reset
  input wire [WW_WIDTH-1:0] wave_width_in,
	input wire is_on_in,
	input wire [23:0] playback_rate_in,   // playback interval in clk cycles per sample
	output logic [WW_WIDTH-1:0] sample_index_out
);

// playback
/**
  NOTE: In this form, the playback counter resets everytime is_on_in goes low. 
  It immedeately cuts off the data output, and resets the sample index.

  NOTE: The sample index naturally wraps around to 0 after 65536 samples.
*/
logic [23:0] playback_counter;

always_ff @(posedge clk_in) begin
  if (rst_in) begin
    playback_counter <= 24'b0;
    sample_index_out <= 18'b0;
  end else begin
    // is_on_in is high
    if (is_on_in) begin
      // hit playback rate interval, output next sample 
      if (playback_counter >= playback_rate_in) begin
        playback_counter <= 24'b0;

        // increment the sample index
        if (sample_index_out+1 >= wave_width_in) begin
          sample_index_out <= 18'b0;
        end else begin
          sample_index_out <= sample_index_out + 1;
        end
      end 

      // otw, keep counting
      else begin
        playback_counter <= playback_counter + 1;
      end

    // is_on_in is low, reset the playback counter and sample index
    end else begin
      playback_counter <= 24'b0;
      sample_index_out <= 18'b0;
    end
  end
end


// // playback (alternative implementation)
// /**
//   NOTE: In this form, the playback counter does not reset when is_on_in goes low. 
//   It continues to output the wave until the sample index wraps back around to 0.

//   NOTE: The sample index naturally wraps around to 0 after 512 samples.
// */

// always_ff @(posedge clk_in) begin
//   if (rst_in) begin
//     playback_counter <= 24'b0;
//     sample_index_out <= 16'b0;
//   end else begin
//     // is_on_in is low & we're at the end of the sample, stop playback
//     if (~is_on_in & sample_index_out == 16'b0) begin
//       playback_counter <= 24'b0;
//     end

//     // is_on_in is high (or it's low, but we still finish the sample)
//     else begin
//       // hit playback rate interval, output next sample 
//       if (playback_counter >= playback_rate_in) begin
//         playback_counter <= 24'b0;

//         // increment the sample index
//         sample_index_out <= sample_index_out + 1;
//       end 

//       // otw, keep counting
//       else begin
//         playback_counter <= playback_counter + 1;
//       end
//     end
//   end
// end




endmodule

`default_nettype wire