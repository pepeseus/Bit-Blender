module midi_reader(
    input wire clk_in, //system clock
    input wire rst_in, //system reset
    input wire rx_wire_in,
    output logic [7:0] data_byte1,
    output logic [7:0] data_byte2,
    output logic [3:0] status
    output logic valid_out
);

    logic receiver_data_out;
    logic [7:0] data_out;
    logic leading_bit;
    assign leading_bit = data_out[7];

   typedef enum {
		 IDLE,
		 STATUS_RECEIVED,
		 BYTE1_RECEIVED
		 } istate;
   istate state;

  uart_receive #(
    .INPUT_CLOCK_FREQ(100_000_000), 
    .BAUD_RATE(31250) // MIDI baud rate
  ) uart_rec (
      .clk_in(clk_100mhz),
      .rst_in(rst_in),
      .rx_wire_in(rx_wire_in),
      .new_data_out(receiver_data_out),
      .data_byte_out(data_out)
  );

    always_ff@(posedge clk_in) begin

        if (rst_in) begin
            data_byte1 <= 0;
            data_byte2 <= 0;
            notePitch <= 0;
            noteOn <= 0;
            state <= IDLE;
            status <= 0;
            valid_out <= 0;
        end

        else if (receiver_data_out) begin // new data

            case(state)

                IDLE: begin
                    if (leading_bit == 1'b1) begin // if we have incoming status byte
                        status <= data_out[6:4];
                        state <= STATUS_RECEIVED;
                        if (valid_out) begin
                            valid_out <= 0;
                        end
                end

                STATUS_RECEIVED: begin
                    if (leading_bit == 1'b1) begin // if we have incoming status byte (again)
                        status <= data_out[6:4]; // overwrite old status and stay in this status
                    end
                    else begin // otherwise we got the first data byte
                        data_byte1 <= data_out;
                        state <= BYTE1_RECEIVED;
                    end
                end

                BYTE1_RECEIVED: begin
                    if (leading_bit == 1'b1) begin // if we have incoming status byte so reset
                        status <= data_out[6:4]; // overwrite old status and stay in this status
                        state <= STATUS_RECEIVED;
                    end
                    else begin // otherwise we got the first data byte
                        data_byte2 <= data_out;
                        state <= IDLE;
                        valid_out <= 1'b1;
                    end
                end

            endcase

            end
        end

    end


    always_comb begin


    end




endmodule // midi_reader