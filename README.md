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




# PMOD breakout:
F14 - MIDI RX in
F15 - I2S BCLK
H13 - I2S SD
H14 - I2S WS
[Urbana board Pmod+ connector](pmod.png)


# Urbana Board Documentation
https://www.realdigital.org/doc/496fed57c6b275735fe24c85de5718c2



# Building bitfile & uploading

lab-bc run . ./obj

openFPGALoader -b arty_s7_50 obj/final.bit

