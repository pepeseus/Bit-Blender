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


  logic [4:0] counter1 = 0;        // 9-bit counter for 100 MHz / 371.25 kHz = 269

  always @(posedge clk_ref or posedge reset) begin
    if (reset) begin
      counter1 <= 0;
      clk_bit <= 0;
    end else if (counter == 23) begin
      counter1 <= 0;
      clk_bit <= ~clk_bit;        // Toggle clk_ws every 269 cycles
    end else begin
      counter1 <= counter1 + 1;
    end
  end
  

endmodule
