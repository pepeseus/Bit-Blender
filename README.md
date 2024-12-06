# Bit-Blender
FPGA Synth


# TODO

- Modify funky_sine J
- Top level + switch to 16 bit A
- MIDI processor J
- Polyphony J
- Wave loader A
- SD card A
- UI handler + potentiometer
- Visual View J
- Debugger View A
- FFT View (?)
- Real-time graph view (?)


NOTES:
- I commented out voltage configs in xdc because there's some conflict between uart_txd 1.8v vs midi_rx 3.3(?) !!! MIDI might not work



Qs:
- GET HDMI OUTS!!!!


# PMOD breakout:
F14 - MIDI RX in
F15 - I2S BCLK
H13 - I2S SD
H14 - I2S WS
[Urbana board Pmod+ connector](pmod.png)


# Urbana Board Documentation
https://www.realdigital.org/doc/496fed57c6b275735fe24c85de5718c2
