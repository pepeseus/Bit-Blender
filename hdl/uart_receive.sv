`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [7:0] data_byte_out
    );

    localparam BAUD_BIT_PERIOD = (INPUT_CLOCK_FREQ + BAUD_RATE - 1) / BAUD_RATE;
    localparam HALF_BAUD_BIT_PERIOD = (BAUD_BIT_PERIOD >> 1) - 1;
    localparam QUARTER_PERIOD = HALF_BAUD_BIT_PERIOD >> 1;
    localparam BAUD_COUNTER_WIDTH = $clog2(BAUD_BIT_PERIOD);
    logic [BAUD_COUNTER_WIDTH-1:0] baud_counter;
    logic [3:0] total_bits;
    logic [1:0] state;
    logic read;
    logic goodEnd;

    always_ff @(posedge clk_in) begin

      if (rst_in) begin
        baud_counter <= 0;
        new_data_out <= 1'b0;
        data_byte_out <= 0;
        total_bits <= 0;
        state <= 2'b00;
        read <= 0;
        goodEnd <= 0;
      end
      else begin
        if (state == 2'b00) begin
            if (rx_wire_in == 1'b0) begin
                read <= ~read;
                data_byte_out <= 0;
                state <= 2'b01;
            end
            new_data_out <= 1'b0;
            baud_counter <= 0;
            total_bits <= 0;
        end
        else if (state == 2'b01) begin // IF START
            if (baud_counter == HALF_BAUD_BIT_PERIOD) begin // Switch to DATA
                state <= 2'b10;
                total_bits <= 0;
            end
            else begin
                if (rx_wire_in == 1'b1) begin // NOT VALID START!!
                    state <= 2'b00; // SWITCH TO IDLE
                end
            end
        end
        else if (state == 2'b11) begin // IF ON STOP
            if (goodEnd == 1'b0) begin

                if (baud_counter == QUARTER_PERIOD) begin
                    goodEnd <= 1'b1;
                end
                else if (rx_wire_in <= 1'b1) begin
                    state <= 2'b00; // we failed go back to idle
                end
            end
            else if (baud_counter == BAUD_BIT_PERIOD - 1) begin // WE MADE IT!!!@!!
                new_data_out <= 1'b1;
                state <= 2'b00;
                goodEnd <= 1'b0;
            end
            end

        end
        else begin
            if (baud_counter == HALF_BAUD_BIT_PERIOD) begin
                read <= ~read;
                else if (state == 2'b10) begin // DATA
                    if (total_bits < 8) begin
                        data_byte_out <= {rx_wire_in, data_byte_out[7:1]};
                        total_bits <= total_bits + 1;
                    end
                    else begin
                        state <= 2'b11; // switch to stop
                    end
                end
            end

            if (baud_counter < BAUD_BIT_PERIOD - 1) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
            end
        end
      end
    end

endmodule // uart_receive

`default_nettype wire
