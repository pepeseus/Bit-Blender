`default_nettype none
module uart_receive #(parameter INPUT_CLOCK_FREQ=100_000_000, parameter BAUD_RATE=57600)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          rx_wire_in,
    output logic[7:0]   data_byte_out,
    output logic        new_data_out    // signal new data valid
  );

  localparam int UART_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

  enum { IDLE, START, DATA, STOP, TRANSMIT } state;

  // data
  logic[7:0] data_frame;

  // bit period counter
  logic [31:0] bit_period;         // CLK cycles counter in between data 
  logic bit_period_rst;
  counter bit_period_counter (  
    .clk_in(clk_in),
    .rst_in(bit_period_rst),
    .period_in(UART_BIT_PERIOD),
    .count_out(bit_period)         // counts CLK cycles between 0 and UART_BIT_PERIOD, and then loops around
  );
  assign bit_period_rst = (state == START | state == DATA | state == STOP) ? 0 : 1;   // hold reset while in IDLE or TRANSMIT state

  // bit counter
  logic[3:0] cur_bit_number; // first bit number is 1, not 0
 
  // flow logic
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= IDLE; // reset state
      data_byte_out <= 0;
      new_data_out <= 0;
      data_frame <= 0;
      cur_bit_number <= 0;
    end

    // transition logic
    else begin  
      case (state)
        IDLE: begin 
            if (~rx_wire_in) state <= START;    // 0 detected, begin count
            data_byte_out <= 0;                 // reset data byte out
            new_data_out <= 0;
            data_frame <= 0;
            cur_bit_number <= 0;
          end

        START: begin
            // sample the bit in the middle of the bit transaction period!
            if (bit_period == UART_BIT_PERIOD/2) begin
              if (~rx_wire_in) state <= DATA;   // 0 detected, good START bit confirmed, move to sampling DATA
              else state <= IDLE;               // 1 detected, bad START bit (glitch?), discard transaction
            end
          end
        
        DATA: begin
            if (bit_period == 0) begin
              cur_bit_number <= cur_bit_number + 1;
            end
            if (bit_period == UART_BIT_PERIOD/2) begin
              data_byte_out <= {rx_wire_in, data_byte_out[7:1]};   // read data bit in (lsb first order)
              // last bit, change state
              if (cur_bit_number == 8) state <= STOP;
            end
          end

        STOP: begin
            if (bit_period == UART_BIT_PERIOD/2) begin
              if (rx_wire_in) state <= TRANSMIT;    // 1 detected, good STOP bit confirmed, move to sampling TRANSMIT
              else state <= IDLE;                   // 0 detected, bad STOP bit (glitch?), discard transaction
            end
          end

        TRANSMIT: begin
            new_data_out <= 1;            // signal data ready
            state <= IDLE;
          end
      endcase
    end
  end

endmodule
