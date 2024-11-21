`timescale 1ns / 1ps
`default_nettype none


//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_bit__74.25000______0.000______50.0______337.616____322.999
// clk_ws__371.25000______0.000______50.0______258.703____322.999
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________100.000____________0.010

module i2s_clk_wiz_44100 (
  // Status and control signals
  input  wire       reset,
  input  wire       clk_ref,
  // Clock out ports
  output logic      clk_bit,
  output logic      clk_ws,
 );

  // 100,000,000 / 44,100 / 24 / 2 / 2 (Xilinx clock / sample rate / bits per sample / channels / edges);
  // = 23.62
  localparam i2s_bclk_ncycles = 5'd24;
  localparam i2s_ws_nbits = 5'd24;


  logic [4:0] counter_bit = 0;
  logic [4:0] counter_ws = 0;

  always @(posedge clk_ref) begin
    if (reset) begin
      counter_bit <= 0;
      clk_bit <= 0;
      counter_ws <= 0;
    end else 
    
    if (counter_bit == i2s_bclk_ncycles) begin
      counter_bit <= 0;
      clk_bit <= ~clk_bit;        // Toggle clk_bit every 24 cycles of 100MHz clock

      // falling edge of bclk
      if (clk_bit == 1'b1) begin

        if (counter_ws == i2s_ws_nbits) begin
          counter_ws <= 0;
          clk_ws <= ~clk_ws;      // Toggle clk_ws every 24 cycles (for 24 bits of data) of clk_bit

        end else begin
          counter_ws <= counter_ws + 1;
        end

      end
    end 
    
    else begin
      counter_bit <= counter_bit + 1;
    end

	
  end
  

endmodule
