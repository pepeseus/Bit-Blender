module midi_reader(
    input wire clk_in,         // System clock
    input wire rst_in,         // System reset
    input wire rx_wire_in,     // UART RX input
    output logic [3:0] status, // MIDI status
    output logic [7:0] data_byte1,
    output logic [7:0] data_byte2,
    output logic valid_out
);

    logic receiver_data_out;
    logic [7:0] data_out;
    logic leading_bit;

    // Extract the leading bit of the data byte
    assign leading_bit = data_out[7];

    // State enumeration for state machine
    typedef enum logic [1:0] {
        IDLE,
        STATUS_RECEIVED,
        BYTE1_RECEIVED
    } istate;
    istate state;

    // Instantiate UART receiver
    uart_receive #(
        .INPUT_CLOCK_FREQ(100_000_000), 
        .BAUD_RATE(31250) // MIDI baud rate
    ) uart_rec (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rx_wire_in(rx_wire_in),
        .new_data_out(receiver_data_out),
        .data_byte_out(data_out)
    );

    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            data_byte1 <= 8'd0;
            data_byte2 <= 8'd0;
            status <= 4'd0;
            state <= IDLE;
            valid_out <= 1'b0;
        end else if (receiver_data_out) begin // New data received
            case (state)
                IDLE: begin
                    if (leading_bit == 1'b1) begin // Incoming status byte
                        status <= data_out[6:4];
                        state <= STATUS_RECEIVED;
                        valid_out <= 1'b0;
                    end
                end

                STATUS_RECEIVED: begin
                    if (leading_bit == 1'b1) begin // Another status byte
                        status <= data_out[6:4]; // Overwrite old status
                    end else begin // First data byte received
                        data_byte1 <= data_out;
                        state <= BYTE1_RECEIVED;
                    end
                end

                BYTE1_RECEIVED: begin
                    if (leading_bit == 1'b1) begin // Another status byte
                        status <= data_out[6:4];
                        state <= STATUS_RECEIVED;
                    end else begin // Second data byte received
                        data_byte2 <= data_out;
                        state <= IDLE;
                        valid_out <= 1'b1; // Indicate valid output
                    end
                end

            endcase
        end
    end

endmodule
