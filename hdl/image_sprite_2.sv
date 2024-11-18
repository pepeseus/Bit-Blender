`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite_2 #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  input wire pop,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  logic [7:0] dataOutImageBROM; 
  logic [23:0] dataOutPaletteBROM;

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT*2)-1:0] image_addr;
  assign image_addr = pop ? (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) : ((hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) + WIDTH*HEIGHT);
  

  logic in_sprite;
  assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
                      (vcount_in >= y_in && vcount_in < (y_in + HEIGHT)));

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? dataOutPaletteBROM[23:16] : 8'hF0;
  assign green_out =  in_sprite ? dataOutPaletteBROM[15:8] : 8'hF0;
  assign blue_out =   in_sprite ? dataOutPaletteBROM[7:0]: 8'hF0;



xilinx_single_port_ram_read_first #(
.RAM_WIDTH(8),                       // Specify RAM data width
.RAM_DEPTH(WIDTH*HEIGHT*2),                     // Specify RAM depth (number of entries)
.RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
.INIT_FILE(`FPATH(image2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
) image_inst (
.addra(image_addr),     // Address bus, width determined from RAM_DEPTH
.dina(0),       // RAM input data, width determined from RAM_WIDTH
.clka(pixel_clk_in),       // Clock
.wea(0),         // Write enable
.ena(1),         // RAM Enable, for additional power savings, disable port when not in use
.rsta(rst_in),       // Output reset (does not affect memory contents)
.regcea(1),   // Output register enable
.douta(dataOutImageBROM)      // RAM output data, width determined from RAM_WIDTH
);

xilinx_single_port_ram_read_first #(
.RAM_WIDTH(24),                       // Specify RAM data width
.RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
.RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
.INIT_FILE(`FPATH(palette2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
) palette_inst (
.addra(dataOutImageBROM),     // Address bus, width determined from RAM_DEPTH
.dina(0),       // RAM input data, width determined from RAM_WIDTH
.clka(pixel_clk_in),       // Clock
.wea(0),         // Write enable
.ena(1),         // RAM Enable, for additional power savings, disable port when not in use
.rsta(rst_in),       // Output reset (does not affect memory contents)
.regcea(1),   // Output register enable
.douta(dataOutPaletteBROM)      // RAM output data, width determined from RAM_WIDTH
);


endmodule

`default_nettype none
