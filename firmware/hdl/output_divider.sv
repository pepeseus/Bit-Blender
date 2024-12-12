`timescale 1ns / 1ps
`default_nettype none


module output_divider #(
  parameter NUM_OSCILLATORS,
  parameter SAMPLE_WIDTH,
  parameter PRE_DIVISION_AUDIO_SIZE
)(
  input wire clk_in,
  input wire rst_in,
  input wire [PRE_DIVISION_AUDIO_SIZE-1:0] stream_in,
  input wire [NUM_OSCILLATORS-1:0] is_on,
  input wire has_updated,
  output logic [SAMPLE_WIDTH-1:0] stream_out
);

    // typedef enum logic {
    //     IDLE,
    //     DIVIDING
    // } istate;
    // istate state;

    logic [PRE_DIVISION_AUDIO_SIZE-1:0] num_on;


    // DIVIDER VARIABLES

    logic [31:0] quotient;
    logic [31:0] remainder;
    logic data_valid_divider;
    logic error_divider;
    logic busy_divider;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            stream_out <= 0;
            // state <= IDLE;
        end else if (data_valid_divider) begin
            stream_out <= quotient[SAMPLE_WIDTH-1:0];
        end

    end

    always_comb begin
        num_on = 0;
        for (int j = 0; j < NUM_OSCILLATORS; j++) begin
            num_on += is_on[j];
        end
        if (num_on == 0) begin
            num_on = 1;
        end
    end

    divider #(.WIDTH(PRE_DIVISION_AUDIO_SIZE)) wave_divider (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(stream_in),
        .divisor_in(num_on),
        .data_valid_in(~busy_divider),
        .quotient_out(quotient),
        .remainder_out(remainder),
        .data_valid_out(data_valid_divider),
        .error_out(error_divider),
        .busy_out(busy_divider)
    );


endmodule


`default_nettype wire