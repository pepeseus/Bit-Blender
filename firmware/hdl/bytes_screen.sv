`timescale 1ns / 1ps
`default_nettype none

module bytes_screen #(
  // parameter BAUD_RATE=1
  // parameter BAUD_RATE=4800
  parameter BAUD_RATE=9600
  // parameter BAUD_RATE=460800
  )(
	input wire                                      clk_in,                 // system clock
  input wire                                      rst_in,                 // system reset
	input wire [WW_WIDTH-1:0]                       wave_width_in,          // UI switches
  input wire [NUM_OSCILLATORS-1:0][WW_WIDTH-1:0]  osc_indices,            // playback sample index for each oscillator
	input wire                                      bytes_screen_data_ready,// debug sample data
	input wire [SAMPLE_WIDTH-1:0]                   bytes_screen_data_in,   // debug sample data
  output logic [WW_WIDTH-1:0]                     bytes_screen_index_out, // debug sample index requested
  output logic                                    uart_txd,                // UART TX wire
  output logic [7:0]                              analyzer                // UART TX data
);

  localparam NUM_OSCILLATORS = 4;       // FIXED TO 4 FOR THIS PROTOCOL
  localparam WW_WIDTH = 18;             // FIXED TO 18 FOR THIS PROTOCOL
  localparam SAMPLE_WIDTH = 16;         // FIXED TO 16 FOR THIS PROTOCOL


// TODO add potentiometer start index

// 24 fps * 2 bytes per sample * 262141 max wave length = 12_582_768 bytes/s

/**
  BYTES SCREEN PROTOCOL

  1. "WAVWID" - 6 bytes
  2. wave_width_in - 3 bytes
  3. "OSCIDX" - 6 bytes
  4. osc_indices - 12 bytes ~ 4*3 bytes
  5. "WAVDAT" - 6 bytes
  6. bytes_screen_data_in - up to 16 bits ~ 2 bytes
*/
typedef enum { IDLE, WAVWID, WAVWID_SEND, OSCIDX, OSCIDX_SEND, WAVDAT, WAVDAT_BUF, WAVDAT_SEND, LAST_WAVDAT_SEND } state_t;
state_t       state;

logic [47:0]  send_bytes;    // in 3 bytes packets
logic [3:0]   send_index;


// State Machine
always_ff @(posedge clk_in) begin

  if (rst_in) begin
    state <= IDLE;
    send_bytes <= 48'b0;
    send_index <= 0;
    uart_tx_trigger <= 1'b0;

    bytes_screen_index_out <= 1'b0;
  end else begin
    uart_tx_trigger <= 1'b0;

    // only if UART is not busy
    if (~uart_tx_busy) begin
    // if (~uart_tx_busy & bytes_screen_data_ready) begin
      if (state != IDLE) begin
        uart_tx_trigger <= 1'b1;
      end

      case(state)
        IDLE: begin
          state <= WAVWID;
          send_bytes <= 48'h44_49_57_56_41_57; // "WAVWID" big endian
          send_index <= 0;
        end

        WAVWID: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte

          if (send_index == 5) begin      // 6 bytes sent
            state <= WAVWID_SEND;
            send_bytes <= { wave_width_in[7:0], wave_width_in[15:8], 6'b0, wave_width_in[17:16] };  // wave_width_in big endian
            send_index <= 0;
          end
        end

        WAVWID_SEND: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte

          if (send_index == 2) begin      // 3 bytes sent
            state <= OSCIDX;
            send_bytes <= 48'h58_44_49_43_53_4F; // "OSCIDX" big endian
            send_index <= 0;
          end
        end

        OSCIDX: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte

          if (send_index == 5) begin      // 6 bytes sent
            state <= OSCIDX_SEND;
            send_bytes <= { osc_indices[0][7:0], osc_indices[0][15:8], 6'b0, osc_indices[0][17:16] }; // osc_indices[0] big endian
            send_index <= 0;
          end
        end

        OSCIDX_SEND: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte
          
          // for (integer i = 1; i < NUM_OSCILLATORS; i++) begin
          //   if (send_index == 3*i-1) begin      // 3 bytes for prev oscillator index sent
          //     send_bytes <= { osc_indices[i][7:0], osc_indices[i][15:8], 6'b0, osc_indices[i][17:16] }; // osc_indices[i] big endian
          //   end
          // end

          if (send_index == 3*1-1) begin      // 3 bytes for prev oscillator index sent
            send_bytes <= { osc_indices[1][7:0], osc_indices[1][15:8], 6'b0, osc_indices[1][17:16] }; // osc_indices[i] big endian
          end

          if (send_index == 3*2-1) begin      // 3 bytes for prev oscillator index sent
            send_bytes <= { osc_indices[2][7:0], osc_indices[2][15:8], 6'b0, osc_indices[2][17:16] }; // osc_indices[i] big endian
          end

          if (send_index == 3*3-1) begin      // 3 bytes for prev oscillator index sent
            send_bytes <= { osc_indices[3][7:0], osc_indices[3][15:8], 6'b0, osc_indices[3][17:16] }; // osc_indices[i] big endian
          end

          if (send_index == NUM_OSCILLATORS*3-1) begin         // 12 bytes sent
              state <= WAVDAT;
              send_bytes <= 48'h54_41_44_56_41_57;  // "WAVDAT" big endian
              send_index <= 0;
            end
        end

        WAVDAT: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte

          if (send_index == 3) begin
            bytes_screen_index_out <= 1'b0;
          end

          if (send_index == 4) begin      // 6 bytes sent
            state <= WAVDAT_BUF;
            bytes_screen_index_out <= 1'b1; // request next sample
          end
        end

        // pipelining data from the BRAM, no trigger uart
        WAVDAT_BUF: begin
          state <= WAVDAT_SEND;
          send_index <= 0;
          send_bytes <= { bytes_screen_data_in[7:0], bytes_screen_data_in[15:8] };  // bytes_screen_data_in big endian
          bytes_screen_index_out <= 2; // request next sample
        end

        WAVDAT_SEND: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte

          if (send_index == 1) begin      // 2 bytes sent
            send_bytes <= { bytes_screen_data_in[7:0], bytes_screen_data_in[15:8] };
            send_index <= 0;

            if (bytes_screen_index_out+1 < wave_width_in) begin
              bytes_screen_index_out <= bytes_screen_index_out + 1; // request next sample
            end else begin
              state <= LAST_WAVDAT_SEND; // read the last sample
            end
          end
        end

        LAST_WAVDAT_SEND: begin
          send_index <= send_index + 1;
          send_bytes <= send_bytes >> 8;  // next byte

          if (send_index == 1) begin      // 3 bytes sent
            state <= IDLE;
            send_bytes <= 48'h0;          // reset
            send_index <= 0;
          end
        end

      endcase

    end
  end
end





// UART TX
logic uart_tx_busy;
logic [7:0] uart_tx_data;
logic uart_tx_trigger;

assign uart_tx_data = send_bytes[7:0];

uart_transmit #(
  .INPUT_CLOCK_FREQ(100_000_000),
  .BAUD_RATE(BAUD_RATE)
) uart_tx (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .data_byte_in(uart_tx_data),
  .trigger_in(uart_tx_trigger),
  .busy_out(uart_tx_busy),
  .tx_wire_out(uart_txd)
);


endmodule

`default_nettype wire
