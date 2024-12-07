`default_nettype none
module evt_counter #(parameter MAX_COUNT=65_535)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          evt_in,
    output logic[$clog2(MAX_COUNT)-1:0]  count_out
  );
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      // reset
      count_out <= 16'b0;

    end else begin
      if (evt_in) begin
        // increment until hit MAX_COUNT, then loop around
        count_out <= (count_out == MAX_COUNT) ? 0 : count_out + 1;
      end
    end
  end
endmodule // evt_counter

module clk_counter #(parameter MAX_COUNT=65_535)
  ( input wire          clk_in,
    input wire          rst_in,
    output logic[$clog2(MAX_COUNT)-1:0]  count_out
  );
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      // reset
      count_out <= 16'b0;

    end else begin
      // increment until hit MAX_COUNT, then loop around
      count_out <= (count_out == MAX_COUNT) ? 0 : count_out + 1;
    end
  end
endmodule // clk_counter
`default_nettype wire