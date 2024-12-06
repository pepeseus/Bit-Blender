// `timescale 1ns / 1ps
// `default_nettype none


// module midi_coordinator #(
//   parameter NUM_OSCILLATORS,
//   parameter SAMPLE_WIDTH
// )(
//   input wire clk_in,
//   input wire rst_in,
//   input wire isNoteOn,
//   input wire [23:0] cycles_between_samples,
//   input wire valid_in,
//   input wire [NUM_OSCILLATORS-1:0] is_on,
//   input wire [SAMPLE_WIDTH-1:0] out_samples [NUM_OSCILLATORS-1:0],
//   output logic [SAMPLE_WIDTH-1:0] stream_out
// );


//   logic [31:0] age [NUM_OSCILLATORS-1:0]; // LRU approach; keep track of how old each oscillator is

//   always_ff @(posedge clk_in) begin

//     if (rst_in) begin

//       for (int i = 0; i < NUM_OSCILLATORS; i++) begin

//         is_on[i] <= 0;
//         playback_rates[i] <= 0;
//         age[i] <= 0;

//       end

//     end else if (valid_in) begin

//       if (isNoteOn) begin // find available oscillator to replace

//         integer available_idx = -1;
//         integer oldest_idx = 0;
//         integer max_age = -1;

//         for (int i = 0; i < NUM_OSCILLATORS; i++) begin

//           if (!is_on[i]) begin
//             available_idx = i;
//           end

//           if (age[i] > max_age) begin
//             max_age = age[i];
//             oldest_idx = i;
//           end

//         end

//         // oscillator found! assign values
//         if (available_idx != -1) begin
//           i = available_idx;
//         end else begin
//           i = oldest_idx;
//         end

//         is_on[i] <= 1;
//         playback_rates[i] <= cycles_between_samples;
//         age[i] <= 0;

//       end else begin // else Note Off so turn off corresponding oscillator

//         for (int i = 0; i < NUM_OSCILLATORS; i++) begin

//           if (is_on[i] && playback_rates[i] == cycles_between_samples) begin
//             is_on[i] <= 0;
//             playback_rates[i] <= 0;
//           end
//         end

//       end

//       // update age for all active oscillators
//       for (int i = 0; i < NUM_OSCILLATORS; i++) begin
//         if (is_on[i]) begin
//             age[i] <= age[i] + 1;
//         end
//       end
//     end
//   end

//   // mix output
//   // TODO: how many oscillators until we don't meet timing?
//   always_comb begin
//     stream_out = 0;
//     for (int i = 0; i < NUM_OSCILLATORS; i++) begin
//       if (is_on[i]) begin
//         stream_out += out_samples[i];
//       end
//     end
//   end

// endmodule


// `default_nettype wire