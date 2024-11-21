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

  

endmodule
