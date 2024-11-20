module Oscillator (
	input wire clk_in,    // system clock
  input wire rst_in,    // system reset
	input wire is_on_in,                 // 
	input wire [23:0] playback_rate_in,  // playback interval in clk cycles per sample
	output logic [23:0] sample_data_out
);



// playback
/**
  NOTE: In this form, the playback counter resets everytime is_on_in goes low. 
  It immedeately cuts off the data output, and resets the sample index.

  NOTE: The sample index naturally wraps around to 0 after 512 samples.
*/
logic [8:0] sample_index = 0;       // index of the sample in the waveform

always_ff @(posedge clk_in) begin
  if (rst_in) begin
    playback_counter <= 24'b0;
    sample_index <= 9'b0;
  end else begin
    // is_on_in is high
    if (is_on_in) begin
      // hit playback rate interval, output next sample 
      if (playback_counter >= playback_rate_in) begin
        playback_counter <= 24'b0;

        // increment the sample index
        sample_index <= sample_index + 1;
      end 

      // otw, keep counting
      else begin
        playback_counter <= playback_counter + 1;
      end

    // is_on_in is low, reset the playback counter and sample index
    end else begin
      playback_counter <= 24'b0;
      sample_index <= 9'b0;
    end
  end
end


// // playback (alternative implementation)
// /**
//   NOTE: In this form, the playback counter does not reset when is_on_in goes low. 
//   It continues to output the wave until the sample index wraps back around to 0.

//   NOTE: The sample index naturally wraps around to 0 after 512 samples.
// */

// always_ff @(posedge clk_in) begin
//   if (rst_in) begin
//     playback_counter <= 24'b0;
//     sample_index <= 9'b0;
//   end else begin
//     // is_on_in is low & we're at the end of the sample, stop playback
//     if (~is_on_in & sample_index == 9'b0) begin
//       playback_counter <= 24'b0;
//     end

//     // is_on_in is high (or it's low, but we still finish the sample)
//     else begin
//       // hit playback rate interval, output next sample 
//       if (playback_counter >= playback_rate_in) begin
//         playback_counter <= 24'b0;

//         // increment the sample index
//         sample_index <= sample_index + 1;
//       end 

//       // otw, keep counting
//       else begin
//         playback_counter <= playback_counter + 1;
//       end
//     end
//   end
// end




// data

xilinx_true_dual_port_read_first_1_clock_ram #(
  .RAM_WIDTH(24),
  .RAM_DEPTH(512),
  .RAM_PERFORMANCE("HIGH_PERFORMANCE")) 
waveform_ram (
  .clka(clk_in),     // Clock

  //writing port:
  .addra(),     // Port A address bus,
  .dina(),      // Port A RAM input data
  .douta(),     // Port A RAM output data, width determined from RAM_WIDTH
  .wea(1'b0),   // Port A write enable
  .ena(1'b0),   // Port A RAM Enable (DISABLED)
  .rsta(1'b0),      // Port A output reset
  .regcea(1'b1),    // Port A output register enable

  //reading port:
  .addrb(hcount_in),   // Port B address bus,
  .doutb(sample_data_out),    // Port B RAM output data,
  .dinb(1'b0),                // Port B RAM input data, width determined from RAM_WIDTH
  .web(1'b0),                 // Port B write enable
  .enb(1'b1),       // Port B RAM Enable,
  .rstb(1'b0),      // Port B output reset
  .regceb(1'b1)     // Port B output register enable
);



// 50,000,000 / 44,100 / 16 / 2 / 2 (DE0 Nano clock / sample rate / bits per sample / channels / edges);
localparam i2sTicks = 8'd18;  // 17.7154195

reg [11:0] i2sCount = 0;
reg [23:0] noteSampleCount = 0;
reg [7:0] bitCount = 15;
reg [7:0] sampleIndex = 0;
reg [7:0] waveTableIndex = 0;
reg [7:0] modulation = 0;
reg isSamplePlaying = 0;
reg isSoundPlaying = 0;

wire [15:0] waveTableSample0;
wire [15:0] waveTableSample1;
wire [15:0] waveTableSample2;
wire [15:0] renderedSample;

WaveTable0Rom waveTable0Rom(waveTableIndex, CLOCK_50, waveTableSample0);
WaveTable1Rom waveTable1Rom(waveTableIndex, CLOCK_50, waveTableSample1);
WaveTable2Rom waveTable2Rom(waveTableIndex, CLOCK_50, waveTableSample2);

SampleMixer sampleMixer(waveTableSample0, waveTableSample1, waveTableSample2, modulation, renderedSample);

always @(posedge CLOCK_50)
begin
	i2sCount <= i2sCount + 1'b1;
	
	// trigger next i2s data bit
	if (i2sCount == i2sTicks)
		begin
			i2sCount <= 1'b0;
			
			i2sBitClock <= ~i2sBitClock;
			
			if (i2sBitClock == 1'b1)
				begin
					if (isSoundPlaying)
						i2sSoundData <= renderedSample[bitCount +: 1];
					else
						i2sSoundData <= 1'b0;
	
					if (bitCount == 0)
						begin
							i2sLeftRightSelect <= ~i2sLeftRightSelect;
							bitCount <= 15;
							
							if (i2sLeftRightSelect == 1'b1)
								begin
									waveTableIndex <= sampleIndex;
									modulation <= modulationValue;
									isSoundPlaying <= isSamplePlaying;
								end
						end
					else
						bitCount <= bitCount - 1'b1;
				end
		end
		
	noteSampleCount <= noteSampleCount + 1'b1;
	
	if (noteSampleCount >= noteSampleTicks)
		begin
			noteSampleCount <= 1'b0;
			sampleIndex <= isSamplePlaying ? sampleIndex + 1'b1 : 1'b0;
					
			if (isNoteOn == 1'b1)
				isSamplePlaying <= 1'b1;	
			else if (sampleIndex == 1'b0)
				isSamplePlaying <= 1'b0;
		end
end

endmodule
