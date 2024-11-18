`default_nettype none

module line_buffer (
            input wire clk_in, //system clock
            input wire rst_in, //system reset

            input wire [10:0] hcount_in, //current hcount being read
            input wire [9:0] vcount_in, //current vcount being read
            input wire [15:0] pixel_data_in, //incoming pixel
            input wire data_valid_in, //incoming  valid data signal

            output logic [KERNEL_SIZE-1:0][15:0] line_buffer_out, //output pixels of data
            output logic [10:0] hcount_out, //current hcount being read
            output logic [9:0] vcount_out, //current vcount being read
            output logic data_valid_out //valid data out signal
  );
  parameter HRES = 1280;
  parameter VRES = 720;

  localparam KERNEL_SIZE = 3;

  // to help you get started, here's a bram instantiation.
  // you'll want to create one BRAM for each row in the kernel, plus one more to
  // buffer incoming data from the wire:

  // da holds
  logic [15:0] bram_out[3:0];
  logic [1:0] counter;

  // da pipes
  logic data_valid_pipe[1:0];
  logic [10:0] hcount_pipe[1:0];
  logic [9:0] vcount_pipe[1:0];

  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin
      xilinx_true_dual_port_read_first_1_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(HRES),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")) line_buffer_ram (
        .clka(clk_in),     // Clock
        //writing port:
        .addra(hcount_in),   // Port A address bus,
        .dina(pixel_data_in),     // Port A RAM input data
        .wea(data_valid_in && (counter == i)), // Port A write enable
        //reading port:
        .addrb(hcount_in),   // Port B address bus,
        .doutb(bram_out[i]),    // Port B RAM output data,
        .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
        .dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
        .web(1'b0),       // Port B write enable
        .ena(1'b1),       // Port A RAM Enable
        .enb(1'b1),       // Port B RAM Enable,
        .rsta(1'b0),     // Port A output reset
        .rstb(1'b0),     // Port B output reset
        .regcea(1'b1), // Port A output register enable
        .regceb(1'b1) // Port B output register enable
      );
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    
    if (rst_in) begin

      counter <= 0;
      data_valid_pipe[0] <= 0;
      data_valid_pipe[1] <= 0;

      hcount_pipe[0] <= 0;
      hcount_pipe[1] <= 0;
      vcount_pipe[0] <= 0;
      vcount_pipe[1] <= 0;

    end else begin

      // handle pipes

      data_valid_pipe[0] <= data_valid_in;
      data_valid_pipe[1] <= data_valid_pipe[0];

      hcount_pipe[0] <= hcount_in;
      hcount_pipe[1] <= hcount_pipe[0];

      vcount_pipe[0] <= vcount_in;
      vcount_pipe[1] <= vcount_pipe[0];

      // increment counter when you reach the end of the horiz line
      if (data_valid_in && hcount_in == HRES-1) begin
          counter <= counter + 2'd01;
      end
    end
  end

  always_comb begin
    case (counter)
      2'b00: begin // oldest -> youngest: 1, 2, 3
          line_buffer_out[0] = bram_out[1]; // vcount-3
          line_buffer_out[1] = bram_out[2]; // vcount-2
          line_buffer_out[2] = bram_out[3]; // vcount-1
      end
      2'b01: begin // oldest -> youngest: 2, 3, 0
          line_buffer_out[0] = bram_out[2]; // vcount-3
          line_buffer_out[1] = bram_out[3]; // vcount-2
          line_buffer_out[2] = bram_out[0]; // vcount-1
      end
      2'b10: begin // oldest -> youngest: 3, 0, 1
          line_buffer_out[0] = bram_out[3]; // vcount-3
          line_buffer_out[1] = bram_out[0]; // vcount-2
          line_buffer_out[2] = bram_out[1]; // vcount-1
      end
      default: begin // 2'b11: oldest -> youngest: 0, 1, 2
          line_buffer_out[0] = bram_out[0]; // vcount-3
          line_buffer_out[1] = bram_out[1]; // vcount-2
          line_buffer_out[2] = bram_out[2]; // vcount-1
      end
    endcase

    hcount_out = hcount_pipe[1];

    if (vcount_pipe[1] >= KERNEL_SIZE - 1) begin
      vcount_out = vcount_pipe[1] - KERNEL_SIZE + 1;
    end else if (vcount_pipe[1] == 0) begin
      vcount_out = VRES - 1;
    end else if (vcount_pipe[1] == 'd00) begin
      vcount_out = VRES - 2;
    end else begin
      vcount_out = VRES - KERNEL_SIZE + vcount_pipe[1];
    end

    data_valid_out = data_valid_pipe[1];

   end

endmodule

`default_nettype wire