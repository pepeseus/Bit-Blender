`default_nettype none
module uart_transmit #(parameter INPUT_CLOCK_FREQ=100_000_000, parameter BAUD_RATE=57600)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          trigger_in,
    input wire[7:0]     data_byte_in,
    output logic        tx_wire_out,
    output logic        busy_out
  );

  localparam int BIT_CLK_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

  enum {IDLE, TRANS, FINISH} state;
  logic[15:0] clk_count;
  logic[3:0] bit_count;
  logic[9:0] transact;

  assign busy_out = ~(state == IDLE) | trigger_in;
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= IDLE; // reset state
      tx_wire_out <= 1;
    end

    // transition logic
    else begin  
      case (state)
        // reset and move to TRANS on trigger_in
        IDLE: begin 
            if (trigger_in) begin
              state <= TRANS;
              transact <= {1'b1, data_byte_in, 1'b0};     // grab data {end bit, data, start bit} (to be reversed)
              clk_count <= 16'b1; // reset CLK counter
              bit_count <= 4'b0;  // reset BIT counter

              // output tx_wire
              tx_wire_out <= 0;
            end
          end

        // transmit data until bit_count is reached, move to FINISH
        TRANS: begin 
            // state <= bit_count == 10 ? FINISH : TRANS;

            if (clk_count == BIT_CLK_PERIOD - 1) begin
              clk_count <= 16'b0;         // reset CLK counter
              bit_count <= bit_count + 1; // increment BIT counter
              transact <= transact >> 1;  // shift transaction data by one

              if (bit_count == 9) state <= FINISH;
              // else state 
            end 
            else begin
              clk_count <= clk_count + 1; // increment CLK counter
            end

            // output tx_wire
            tx_wire_out <= transact[0];
          end

        FINISH: begin
          state <= IDLE;
          // output tx_wire
          tx_wire_out <= 1;
        end
      endcase
    end
  end

endmodule
`default_nettype wire