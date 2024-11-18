`timescale 1ns / 1ps
`default_nettype none

module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);

  logic [8:0] q_m;
  logic [4:0] tally;
  logic [4:0] one_count;
  logic [4:0] zero_count;

  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));

  always_comb begin
    one_count = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    zero_count = 8 - one_count;
  end

  always_ff @(posedge clk_in) begin

    if (rst_in) begin
      tally <= 0;
      tmds_out <= 0;
    end
    else begin

      if (ve_in == 0) begin

        tally <= 0;

        case(control_in)

          2'b00: tmds_out <= 10'b1101010100;
          2'b01: tmds_out <= 10'b0010101011;
          2'b10: tmds_out <= 10'b0101010100;
          2'b11: tmds_out <= 10'b1010101011;
          default: tmds_out <= 10'b1101010100;

        endcase


      end else begin

        if (tally == 0 || one_count == zero_count) begin

          tmds_out[9] <= ~q_m[8];
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= (q_m[8]) ? q_m[7:0] : ~(q_m[7:0]);

          if (q_m[8] == 0) begin
            tally <= tally + zero_count - one_count;
          end else begin
            tally <= tally + one_count - zero_count;
          end

        end else begin

            if ((tally[4] == 1 && one_count > zero_count) 
            || (tally[4] == 0 && zero_count > one_count)) begin

              tmds_out[9] <= 0;
              tmds_out[8] <= q_m[8];
              tmds_out[7:0] <= q_m[7:0];
              tally <= (q_m[8]) ? tally + one_count - zero_count : tally - 2 + one_count - zero_count;

            end else begin

              tmds_out[9] <= 1;
              tmds_out[8] <= q_m[8];
              tmds_out[7:0] <= ~(q_m[7:0]);
              tally <= (q_m[8]) ? tally + 2 + zero_count - one_count : tally + zero_count - one_count;

            end
          end
      end
    end
  end
endmodule //end tmds_encoder
`default_nettype wire


          //   if (one_count >= 5) begin // if more ones than zeros

          //     tmds_out[9] <= 0;
          //     tmds_out[8:0] <= q_m;
          //     tally <= (one_count + one_count - 10);

              
          //   end else begin // else more zeros than ones
        
          //     tmds_out[9] <= 1;
          //     tmds_out[8] <= q_m[8];
          //     tmds_out[7:0] <= ~(q_m[7:0]);
          //     tally <= (10 - one_count - one_count - 10);

          //   end

          // end