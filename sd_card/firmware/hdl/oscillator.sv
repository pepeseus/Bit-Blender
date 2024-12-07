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