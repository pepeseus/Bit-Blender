`timescale 1ns / 1ps
`default_nettype none


module midi_coordinator #(
  parameter NUM_OSCILLATORS,
  parameter SAMPLE_WIDTH
)(
  input wire clk_in,
  input wire rst_in,
  input wire isNoteOn,
  input wire valid_in,
  input wire [23:0] cycles_between_samples,
  output logic [23:0] playback_rate [NUM_OSCILLATORS-1:0],
  output logic [NUM_OSCILLATORS-1:0] is_on,
  input wire [NUM_OSCILLATORS-1:0][SAMPLE_WIDTH-1:0] out_samples,
  output logic [SAMPLE_WIDTH-1:0] stream_out,
  output logic test
);


  logic [31:0] age [NUM_OSCILLATORS-1:0]; // LRU approach; keep track of how old each oscillator is

    function int calculate_index();
        int i_avail = -1;
        int i_oldest = 0;
        automatic int curr_oldest = -1;

        for (int j = 0; j < NUM_OSCILLATORS; j++) begin
            if (!is_on[j]) begin
                i_avail = j;
            end
            if (age[j] > curr_oldest) begin
                curr_oldest = age[j];
                i_oldest = j;
            end
        end

        return (i_avail != -1) ? i_avail : i_oldest;
    endfunction

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            for (int j = 0; j < NUM_OSCILLATORS; j++) begin
                is_on[j] <= 0;
                age[j] <= 0;
                playback_rate[j] <= 0;
                test <= 0;
            end
        end else if (valid_in) begin
            if (isNoteOn) begin
                int i = calculate_index();
                test <= 1;
                is_on[i] <= 1;
                age[i] <= 0;
                playback_rate[i] <= cycles_between_samples;
            end
            else begin
                for (int j = 0; j < NUM_OSCILLATORS; j++) begin
                    if (is_on[j] && playback_rate[j] == cycles_between_samples) begin
                        is_on[j] <= 0;
                        playback_rate[j] <= 0;
                    end
                end
                for (int j = 0; j < NUM_OSCILLATORS; j++) begin
                    if (is_on[j]) begin
                        age[j] <= age[j] + 1;
                    end
                end
            end
        end

    end

    always_comb begin
        stream_out = 0;
        for (int j = 0; j < NUM_OSCILLATORS; j++) begin
            if (is_on[j]) begin
                stream_out += (out_samples[j] >> 2);
            end
        end
    end


endmodule


`default_nettype wire