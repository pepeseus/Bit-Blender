`timescale 1ns / 1ps

module top_level(input clk_100mhz, 
                    input sd_cd,
                    input btnr, // replace w/ your system reset

                    output logic spkl, spkr,      // left and right channels of line out port
                             
                    inout [3:0] sd_dat,
                       
                    output logic [15:0] led,
                    output logic sd_reset, 
                    output logic sd_sck, 
                    output logic sd_cmd
    );
    
    logic reset;            // assign to your system reset
    assign reset = btnr;    // if yours isn't btnr
    
    assign sd_dat[2:1] = 2'b11;
    assign sd_reset = 0;
    
    // generate 25 mhz clock for sd_controller 
    logic clk_25mhz;
    clk_wiz_0 clocks(.clk_in1(clk_100mhz), .clk_out1(clk_25mhz));
   
    // sd_controller inputs
    logic rd;                   // read enable
    logic wr;                   // write enable
    logic [7:0] din;            // data to sd card
    logic [31:0] addr;          // starting address for read/write operation
    
    // sd_controller outputs
    logic ready;                // high when ready for new read/write operation
    logic [7:0] dout;           // data from sd card
    logic byte_available;       // high when byte available for read
    logic ready_for_next_byte;  // high when ready for new byte to be written
    
    // handles reading from the SD card
    sd_controller sd(
        .reset(reset), 
        .clk(clk_25mhz), 
        .cs(sd_dat[3]), 
        .mosi(sd_cmd), 
        .miso(sd_dat[0]),                               
        .sclk(sd_sck),                                  
        .ready(ready),                                  // high when ready for new read/write operation
        .address(addr),                                 // starting address for read/write operation (must be divisible by 512)
        .rd(1'b1),                                      // read enable      
        .dout(dout),                                    // read data from sd card
        .byte_available(byte_available),                // high when byte available for read
        .wr(1'b0),                                      // write enable
        .din(),                                         // write data to sd card
        .ready_for_next_byte(ready_for_next_byte)); 
    
    // audio pwm
    logic spk_out;

    audio_PWM pwm(.clk(clk_100mhz), .reset(reset), .music_data(dout), .PWM_out(spk_out));

    assign spkl = spk_out;
    assign spkr = spk_out;
    
endmodule