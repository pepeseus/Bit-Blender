`timescale 1ns / 1ps
`default_nettype none


module convolution (
    input wire clk_in,
    input wire rst_in,
    input wire [KERNEL_SIZE-1:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,
    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    parameter K_SELECT = 0;
    localparam KERNEL_SIZE = 3;


    // Your code here!

    /* Note that the coeffs output of the kernels module
     * is packed in all dimensions, so coeffs should be
     * defined as `logic signed [2:0][2:0][7:0] coeffs`
     *
     * This is because iVerilog seems to be weird about passing
     * signals between modules that are unpacked in more
     * than one dimension - even though this is perfectly
     * fine Verilog.
     */


    // da pipes
    logic data_valid_pipe[3:0];
    logic [10:0] hcount_pipe[3:0];
    logic [9:0] vcount_pipe[3:0];

    logic signed [2:0][2:0][4:0] pixel_cache_red;
    logic signed [2:0][2:0][5:0] pixel_cache_green;
    logic signed [2:0][2:0][4:0] pixel_cache_blue;
    logic signed [2:0][2:0][13:0] mults_reds;
    logic signed [2:0][2:0][13:0] mults_blues;
    logic signed [2:0][2:0][14:0] mults_greens;
    logic signed [17:0] sum_reds;
    logic signed [17:0] sum_blues;
    logic signed [18:0] sum_greens;
    logic signed [4:0] shifted_reds;
    logic signed [4:0] shifted_blues;
    logic signed [5:0] shifted_greens;
    logic signed [4:0] final_red;
    logic signed [5:0] final_green;
    logic signed [4:0] final_blue;

    // outputs for kernel

    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;

    kernels #(.K_SELECT(K_SELECT)) k_inst (
    .rst_in(rst_in),
    .coeffs(coeffs),
    .shift(shift)
    );


    always_ff @(posedge clk_in) begin

      // Make sure to have your output be set with registered logic!
      // Otherwise you'll have timing violations.

                  // handle pipes

            data_valid_pipe[0] <= data_valid_in;
            data_valid_pipe[1] <= data_valid_pipe[0];
            data_valid_pipe[2] <= data_valid_pipe[1];
            data_valid_pipe[3] <= data_valid_pipe[2];


            hcount_pipe[0] <= hcount_in;
            hcount_pipe[1] <= hcount_pipe[0];
            hcount_pipe[2] <= hcount_pipe[1];
            hcount_pipe[3] <= hcount_pipe[2];



            vcount_pipe[0] <= vcount_in;
            vcount_pipe[1] <= vcount_pipe[0];
            vcount_pipe[2] <= vcount_pipe[1];
            vcount_pipe[3] <= vcount_pipe[2];


        if (rst_in) begin

            // data_valid_pipe[0] <= 0;
            // data_valid_pipe[1] <= 0;

            // hcount_pipe[0] <= 0;
            // hcount_pipe[1] <= 0;
            // vcount_pipe[0] <= 0;
            // vcount_pipe[1] <= 0;

            pixel_cache_red[0][0] <= 0;
            pixel_cache_red[0][1] <= 0;
            pixel_cache_red[0][2] <= 0;
            pixel_cache_red[1][0] <= 0;
            pixel_cache_red[1][1] <= 0;
            pixel_cache_red[1][2] <= 0;
            pixel_cache_red[2][0] <= 0;
            pixel_cache_red[2][1] <= 0;
            pixel_cache_red[2][2] <= 0;

            pixel_cache_green[0][0] <= 0;
            pixel_cache_green[0][1] <= 0;
            pixel_cache_green[0][2] <= 0;
            pixel_cache_green[1][0] <= 0;
            pixel_cache_green[1][1] <= 0;
            pixel_cache_green[1][2] <= 0;
            pixel_cache_green[2][0] <= 0;
            pixel_cache_green[2][1] <= 0;
            pixel_cache_green[2][2] <= 0;

            pixel_cache_blue[0][0] <= 0;
            pixel_cache_blue[0][1] <= 0;
            pixel_cache_blue[0][2] <= 0;
            pixel_cache_blue[1][0] <= 0;
            pixel_cache_blue[1][1] <= 0;
            pixel_cache_blue[1][2] <= 0;
            pixel_cache_blue[2][0] <= 0;
            pixel_cache_blue[2][1] <= 0;
            pixel_cache_blue[2][2] <= 0;

            mults_reds[0][0] <= 0;
            mults_reds[0][1] <= 0;
            mults_reds[0][2] <= 0;
            mults_reds[1][0] <= 0;
            mults_reds[1][1] <= 0;
            mults_reds[1][2] <= 0;
            mults_reds[2][0] <= 0;
            mults_reds[2][1] <= 0;
            mults_reds[2][2] <= 0;

            mults_blues[0][0] <= 0;
            mults_blues[0][1] <= 0;
            mults_blues[0][2] <= 0;
            mults_blues[1][0] <= 0;
            mults_blues[1][1] <= 0;
            mults_blues[1][2] <= 0;
            mults_blues[2][0] <= 0;
            mults_blues[2][1] <= 0;
            mults_blues[2][2] <= 0;

            mults_greens[0][0] <= 0;
            mults_greens[0][1] <= 0;
            mults_greens[0][2] <= 0;
            mults_greens[1][0] <= 0;
            mults_greens[1][1] <= 0;
            mults_greens[1][2] <= 0;
            mults_greens[2][0] <= 0;
            mults_greens[2][1] <= 0;
            mults_greens[2][2] <= 0;

            sum_reds <= 0;
            sum_blues <= 0;
            sum_greens <= 0;
            shifted_reds <= 0;
            shifted_blues <= 0;
            shifted_greens <= 0;
            final_red <= 0;
            final_green <= 0;
            final_blue <= 0;

        end else begin




            // update the pixel cache

            if (data_valid_in) begin

                // col 2 to col 1

                pixel_cache_red[0][0] <= pixel_cache_red[0][1];
                pixel_cache_red[1][0] <= pixel_cache_red[1][1];
                pixel_cache_red[2][0] <= pixel_cache_red[2][1];

                pixel_cache_blue[0][0] <= pixel_cache_blue[0][1];
                pixel_cache_blue[1][0] <= pixel_cache_blue[1][1];
                pixel_cache_blue[2][0] <= pixel_cache_blue[2][1];

                pixel_cache_green[0][0] <= pixel_cache_green[0][1];
                pixel_cache_green[1][0] <= pixel_cache_green[1][1];
                pixel_cache_green[2][0] <= pixel_cache_green[2][1];

                // col 3 to col 2

                pixel_cache_red[0][1] <= pixel_cache_red[0][2];
                pixel_cache_red[1][1] <= pixel_cache_red[1][2];
                pixel_cache_red[2][1] <= pixel_cache_red[2][2];

                pixel_cache_blue[0][1] <= pixel_cache_blue[0][2];
                pixel_cache_blue[1][1] <= pixel_cache_blue[1][2];
                pixel_cache_blue[2][1] <= pixel_cache_blue[2][2];

                pixel_cache_green[0][1] <= pixel_cache_green[0][2];
                pixel_cache_green[1][1] <= pixel_cache_green[1][2];
                pixel_cache_green[2][1] <= pixel_cache_green[2][2];

                // new data to col 3

                pixel_cache_red[0][2] <= data_in[0][15:11];
                pixel_cache_red[1][2] <= data_in[1][15:11];
                pixel_cache_red[2][2] <= data_in[2][15:11];

                pixel_cache_blue[0][2] <= data_in[0][4:0];
                pixel_cache_blue[1][2] <= data_in[1][4:0];
                pixel_cache_blue[2][2] <= data_in[2][4:0];

                pixel_cache_green[0][2] <= data_in[0][10:5];
                pixel_cache_green[1][2] <= data_in[1][10:5];
                pixel_cache_green[2][2] <= data_in[2][10:5];

            end  
            
            // MULTIPLYING

            mults_reds[0][0] <= $signed({1'b0, pixel_cache_red[0][0]}) * $signed(coeffs[0][0]);
            mults_reds[0][1] <= $signed({1'b0, pixel_cache_red[0][1]}) * $signed(coeffs[0][1]);
            mults_reds[0][2] <= $signed({1'b0, pixel_cache_red[0][2]}) * $signed(coeffs[0][2]);
            mults_reds[1][0] <= $signed({1'b0, pixel_cache_red[1][0]}) * $signed(coeffs[1][0]);
            mults_reds[1][1] <= $signed({1'b0, pixel_cache_red[1][1]}) * $signed(coeffs[1][1]);
            mults_reds[1][2] <= $signed({1'b0, pixel_cache_red[1][2]}) * $signed(coeffs[1][2]);
            mults_reds[2][0] <= $signed({1'b0, pixel_cache_red[2][0]}) * $signed(coeffs[2][0]);
            mults_reds[2][1] <= $signed({1'b0, pixel_cache_red[2][1]}) * $signed(coeffs[2][1]);
            mults_reds[2][2] <= $signed({1'b0, pixel_cache_red[2][2]}) * $signed(coeffs[2][2]);

            mults_blues[0][0] <= $signed({1'b0, pixel_cache_blue[0][0]}) * $signed(coeffs[0][0]);
            mults_blues[0][1] <= $signed({1'b0, pixel_cache_blue[0][1]}) * $signed(coeffs[0][1]);
            mults_blues[0][2] <= $signed({1'b0, pixel_cache_blue[0][2]}) * $signed(coeffs[0][2]);
            mults_blues[1][0] <= $signed({1'b0, pixel_cache_blue[1][0]}) * $signed(coeffs[1][0]);
            mults_blues[1][1] <= $signed({1'b0, pixel_cache_blue[1][1]}) * $signed(coeffs[1][1]);
            mults_blues[1][2] <= $signed({1'b0, pixel_cache_blue[1][2]}) * $signed(coeffs[1][2]);
            mults_blues[2][0] <= $signed({1'b0, pixel_cache_blue[2][0]}) * $signed(coeffs[2][0]);
            mults_blues[2][1] <= $signed({1'b0, pixel_cache_blue[2][1]}) * $signed(coeffs[2][1]);
            mults_blues[2][2] <= $signed({1'b0, pixel_cache_blue[2][2]}) * $signed(coeffs[2][2]);

            mults_greens[0][0] <= $signed({1'b0, pixel_cache_green[0][0]}) * $signed(coeffs[0][0]);
            mults_greens[0][1] <= $signed({1'b0, pixel_cache_green[0][1]}) * $signed(coeffs[0][1]);
            mults_greens[0][2] <= $signed({1'b0, pixel_cache_green[0][2]}) * $signed(coeffs[0][2]);
            mults_greens[1][0] <= $signed({1'b0, pixel_cache_green[1][0]}) * $signed(coeffs[1][0]);
            mults_greens[1][1] <= $signed({1'b0, pixel_cache_green[1][1]}) * $signed(coeffs[1][1]);
            mults_greens[1][2] <= $signed({1'b0, pixel_cache_green[1][2]}) * $signed(coeffs[1][2]);
            mults_greens[2][0] <= $signed({1'b0, pixel_cache_green[2][0]}) * $signed(coeffs[2][0]);
            mults_greens[2][1] <= $signed({1'b0, pixel_cache_green[2][1]}) * $signed(coeffs[2][1]);
            mults_greens[2][2] <= $signed({1'b0, pixel_cache_green[2][2]}) * $signed(coeffs[2][2]);

            // ADDING

            sum_reds <= $signed(mults_reds[0][0]) + $signed(mults_reds[0][1]) + $signed(mults_reds[0][2]) + $signed(mults_reds[1][0]) + $signed(mults_reds[1][1]) + $signed(mults_reds[1][2]) + $signed(mults_reds[2][0]) + $signed(mults_reds[2][1]) + $signed(mults_reds[2][2]);
            sum_blues <= $signed(mults_blues[0][0]) + $signed(mults_blues[0][1]) + $signed(mults_blues[0][2]) + $signed(mults_blues[1][0]) + $signed(mults_blues[1][1]) + $signed(mults_blues[1][2]) + $signed(mults_blues[2][0]) + $signed(mults_blues[2][1]) + $signed(mults_blues[2][2]);
            sum_greens <= $signed(mults_greens[0][0]) + $signed(mults_greens[0][1]) + $signed(mults_greens[0][2]) + $signed(mults_greens[1][0]) + $signed(mults_greens[1][1]) + $signed(mults_greens[1][2]) + $signed(mults_greens[2][0]) + $signed(mults_greens[2][1]) + $signed(mults_greens[2][2]);
            
            // SHIFTING

            final_red <= ($signed(sum_reds) >>> shift) > $signed({1'b0, 5'b11111})? 5'b11111 : 0 > ($signed(sum_reds) >>> shift) ? 5'b00000 : (sum_reds >>> shift);
            final_green <= ($signed(sum_greens) >>> shift) > $signed({1'b0, 6'b111111})? 6'b111111 : 0 > ($signed(sum_greens) >>> shift) ? 6'b000000 : (sum_greens >>> shift);
            final_blue <= ($signed(sum_blues) >>> shift) > $signed({1'b0, 5'b11111})? 5'b11111 : 0 > ($signed(sum_blues) >>> shift) ? 5'b00000 : (sum_blues >>> shift);

            line_out <= {final_red, final_green, final_blue};
        
        end

    end

    assign data_valid_out = data_valid_pipe[3];
    assign hcount_out = hcount_pipe[3];
    assign vcount_out = vcount_pipe[3];

endmodule

`default_nettype wire

