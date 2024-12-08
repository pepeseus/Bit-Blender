# Bit-Blender
FPGA Synth


# TODO

- DONE Modify funky_sine J
- DONE Top level + switch to 16 bit A
- DONE MIDI processor J
- DONE Wave loader A

- Polyphony J
- SD card A
- Increase max wave width
- UI handler + potentiometer
- Visual View J
- Bytes View A
- FFT View (?)
- Real-time graph view (?)




# PMOD breakout:
F14 - MIDI RX in
F15 - I2S BCLK
H13 - I2S SD
H14 - I2S WS
[Urbana board Pmod+ connector](media/pmod.png)


# Urbana Board Documentation
https://www.realdigital.org/doc/496fed57c6b275735fe24c85de5718c2



# Building bitfile & uploading

lab-bc run . ./obj

openFPGALoader -b arty_s7_50 obj/final.bit


