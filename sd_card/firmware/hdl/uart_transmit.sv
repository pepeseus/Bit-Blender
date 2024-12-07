`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
    );

    localparam BAUD_BIT_PERIOD = (INPUT_CLOCK_FREQ + BAUD_RATE - 1) / BAUD_RATE;
    localparam BAUD_COUNTER_WIDTH = $clog2(BAUD_BIT_PERIOD);
    logic [BAUD_COUNTER_WIDTH-1:0] baud_counter;
    logic [7:0] data_copy;
    logic [4:0] total_counter;

    always_ff @(posedge clk_in) begin
      if (rst_in) begin
        busy_out <= 1'b0;
        tx_wire_out <= 1'b1;
        baud_counter <= 0;
        total_counter <= 0;
      end 
      else begin

        if (trigger_in == 1'b1 && busy_out == 1'b0) begin
          busy_out <= 1'b1;
          data_copy <= data_byte_in;
          tx_wire_out <= 1'b0; // START!!
          baud_counter <= 0;
          total_counter <= 0;
        end
        else if (busy_out == 1'b1) begin
            if (baud_counter == BAUD_BIT_PERIOD - 1) begin
              if (total_counter == 8) begin
                tx_wire_out <= 1'b1; // JUST THE STOP BIT NOW
                baud_counter <= 0;
                total_counter <= total_counter + 1;
              end
              else if (total_counter == 9) begin
                busy_out <= 1'b0; // OK, NOW WE'RE ACTUALLY DONE
                baud_counter <= 0;
                total_counter <= 0;
              end
              else begin
                baud_counter <= 0;
                tx_wire_out <= data_copy[0]; // ARE THESE TWO LINES OK!?
                data_copy <= {1'b0, data_copy[7:1]};
                total_counter <= total_counter + 1;
              end
          end
          else begin
            baud_counter <= baud_counter + 1; // update counter next cycle
          end
        end
      end
    end
   
     
endmodule // uart_transmit

`default_nettype wire