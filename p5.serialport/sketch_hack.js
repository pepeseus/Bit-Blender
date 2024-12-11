/**
 * THIS VERSION OF THE SKETCH HAS UNFIXED BUGS THAT WE MUSKED FOR THE LACK OF TIME FOR THE DEMO
 * 
 * For some reason, the waveData array is not being transmitted properly. The FPGA starts to send the first selected 
 * sample 4 (or 8?) bytes after the "WAVDAT" command. It also doesn't send the last few samples properly.
 * 
 * In this sketch, we simply remove the incorrect samples to save time.
 */


/**
 * SETUP
 */

// variable for p5.SerialPort object
let serial;

// variable por serialPortName
let serialPortName = '/dev/tty.usbserial-8874042402DA1';

// variable for HTML DOM input for serial port name
let htmlInputPortName;

// variable for HTML DOM button for entering new serial port name
let htmlButtonPortName;



// p5.js setup() runs once, at the beginning
function setup() {
  // small canvas
  createCanvas(1800, 1080);

  // set text alignment
  textAlign(LEFT, CENTER);

  // p5.js to create HTML input and set initial value
  htmlInputPortName = createInput(serialPortName);

  // p5.js to create HTML button and set message
  button = createButton('update port');

  // p5.js to add callback function for mouse press
  button.mousePressed(updatePort);

  // create instance of p5.SerialPort
  serial = new p5.SerialPort();

  // print version of p5.serialport library
  console.log('p5.serialport.js ' + serial.version);

  // get a list the ports available
  // you should have a callback defined to see the results
  serial.list();

  // here are the callbacks that you can register

  // when we connect to the underlying server
  serial.on('connected', gotServerConnection);

  // when we get a list of serial ports that are available
  serial.on('list', gotList);

  // When we some data from the serial port
  serial.on('data', gotData);

  // When or if we get an error
  serial.on('error', gotError);

  // When our serial port is opened and ready for read/write
  serial.on('open', gotOpen);

  serial.on('close', gotClose);
}




/**
 * SERIAL CONTROLLER
 */

// callback function to update serial port name
function updatePort() {
  // retrieve serial port name from the text area
  serialPortName = htmlInputPortName.value();
  // open the serial port
  serial.openPort(serialPortName, {baudRate: 9600});
  // serial.openPort(serialPortName);
}

// We are connected and ready to go
function gotServerConnection() {
  print('connected to server');
}

// Got the list of ports
function gotList(list) {
  print('list of serial ports:');
  // list is an array of their names
  for (let i = 0; i < list.length; i++) {
    print(list[i]);
  }
}

// Connected to our serial device
function gotOpen() {
  print('serial port is open');
}

function gotClose() {
  print('serial port is closed');
  latestData = 'serial port is closed';
}

// Ut oh, here is an error, let's log it
function gotError(e) {
  print(e);
}



/**
  BYTES SCREEN PROTOCOL

  1. "WAVWID" - 6 bytes
  2. wave_width_in - 3 bytes
  3. "OSCIDX" - 6 bytes
  4. osc_indices - 12 bytes ~ 4*3 bytes
  5. "WAVDAT" - 6 bytes
  6. bytes_screen_data_in - up to 16 bits ~ 2 bytes
*/

const MAX_SAMPLES = 41*29;

let lastSixBytes = [0, 0, 0, 0, 0, 0];
let waveWidth = 0;
let oscIndices = [0,0,0,0];
let waveData = Array(MAX_SAMPLES).fill("");
let waveSampleIdx = 0;
let newSample = false;

let state = "IDLE" // IDLE, WAVWID, WAVDAT, OSCIDX
let stateByteIdx = 0;

// there is data available to work with from the serial port
function gotData() {
  let inByte = serial.read();

  // update
  lastSixBytes.shift();
  lastSixBytes.push(inByte);

  switch (state) {
    case "WAVWID":
      if (stateByteIdx < 3) {
        waveWidth = (waveWidth << 8) | inByte;
        stateByteIdx++;
      }
      break;

    case "OSCIDX":
      if (stateByteIdx < 3) {
        oscIndices[0] = (oscIndices[0] << 8) | inByte;
        stateByteIdx++;
      } else if (stateByteIdx < 6) {
        oscIndices[1] = (oscIndices[1] << 8) | inByte;
        stateByteIdx++;
      } else if (stateByteIdx < 9) {
        oscIndices[2] = (oscIndices[2] << 8) | inByte;
        stateByteIdx++;
      } else if (stateByteIdx < 12) {
        oscIndices[3] = (oscIndices[3] << 8) | inByte;
        stateByteIdx++;
      }
      break;

    // case "PREWAVDAT":
    //   // HACK! skip the first 2 samples
    //     if (!newSample) {
    //       newSample = true;
    //     } else {
    //       newSample = false;
    //       waveSampleIdx++;
    //     }

    //     if (waveSampleIdx >= 4) {
    //       state = "WAVDAT";
    //       waveSampleIdx = 0;
    //       newSample = false;
    //     }

    case "WAVDAT":
      if (!newSample) {
        let repr = (inByte & 0x80) === 0 ? String.fromCharCode(inByte & 0x7F) : inByte.toString(16);
        waveData[waveSampleIdx] = repr;
        newSample = true;
      } else {
        let repr = (inByte & 0x80) === 0 ? String.fromCharCode(inByte & 0x7F) : inByte.toString(16);
        waveData[waveSampleIdx] = waveData[waveSampleIdx] + repr;
        waveSampleIdx++;
        newSample = false;
      }

      if (waveSampleIdx >= MAX_SAMPLES) {
        state = "IDLE";
      }
      break;
  }

  // h44_49_57_56_41_57 - "DIWVAW"
  if (lastSixBytes[1] == 0x41 && 
    lastSixBytes[2] == 0x56 && 
    lastSixBytes[3] == 0x57 && 
    lastSixBytes[4] == 0x49 && 
    lastSixBytes[5] == 0x44) {
      state = "WAVWID";
      stateByteIdx = 0;
      waveWidth = 0;
  }

  // h58_44_49_43_53_4F - "XDICSO"
  if (lastSixBytes[0] == 0x4F &&
    lastSixBytes[1] == 0x53 &&
    lastSixBytes[2] == 0x43 &&
    lastSixBytes[3] == 0x49 &&
    lastSixBytes[4] == 0x44 &&
    lastSixBytes[5] == 0x58) {
    state = "OSCIDX";
    stateByteIdx = 0;
    oscIndices = [];
  }

  // h54_41_44_56_41_57 - "TADVAW"
  if (lastSixBytes[0] == 0x57 && 
    lastSixBytes[1] == 0x41 &&
    lastSixBytes[2] == 0x56 &&
    lastSixBytes[3] == 0x44 &&
    lastSixBytes[4] == 0x41 &&
    lastSixBytes[5] == 0x54) {
    state = "WAVDAT";
    stateByteIdx = 0;
    waveSampleIdx = 0;
    newSample = false;
  }
}



/**
 * P5.JS DRAW
 */

let hu = 90
let vu = 45
let fontSize = 25

// p5.js draw() runs after setup(), on a loop
function draw() {

  // if (waveWidth < 100) {
  //   hu = 230
  //   vu = 100
  //   fontSize = 80
  // } else if (waveWidth < 500) {
  //   hu = 130
  //   vu = 80
  //   fontSize = 50
  // } else {
  //   hu = 60
  //   vu = 25
  //   fontSize = 20
  // }
  
  background('#3D403E');
  fill('palegreen');
  textFont('Courier New', 10);
  let i = 0
  
	textSize(fontSize);
  for (let y = 30; y <= height-vu; y += vu) {
    for (let x = 30; x <= width-hu; x += hu) {
      if (i < waveWidth-2 && i < MAX_SAMPLES) {   // HACK! not displaying the last 2 samples, they are wrong!
        let bytesStr = waveData[i]
        text(bytesStr, x, y)
        i++
      }
    }
  }

  // TODO indicies squares!
  // TODO ASCII representation of the bytes

  textSize(20);
  text('waveWidth: ' + waveWidth, 30, 1060);

  if (waveWidth > MAX_SAMPLES) {
    text('MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE MORE', 250, 1060);
  }
}