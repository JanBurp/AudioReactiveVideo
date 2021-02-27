/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

boolean debug = true;

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "Zaagstof-drang-kort.wav";

// Basic colors
color backgroundColor = color(128,64,128);

// Timing
int fadeInTime = 30000;
int fadeOutTime = 30000;

// Scenes


// Objects




// =========== DON'T CHANGE ANYTHING UNDER THIS LINE (or know what you do) =========== //

// Time
int startTime = millis();
int endTime = 0; // will be startTime + duration of soundfile
int playTime = 0;


// Audio
import ddf.minim.*;
Minim minim;
AudioPlayer player;

// import processing.sound.*;
// SoundFile sample;
// int soundDuration = 0;

// Amplitude amplitude;
// FFT fft;
// int bands = 16; // power of 2
// AudioAnalyzer analyzer;

// Visuals
float smoothingFactorUp = 0.8;
float smoothingFactorDown = 0.02;

// // Shapes
// int nrOfShapes = 50;
// Shape[] shapes;

// int formResolution = 3;
// int stepSize = 10;
// float speed = 1.5;
// float initRadius = 70;



/*

  SETUP

*/
public void setup() {
  // fullScreen(P2D);
  size(1280,720,P2D);
  // pixelDensity(2);
  background(backgroundColor);

  randomSeed(1);

  // Start Audio
  minim = new Minim(this);
  player = minim.loadFile( audioFile );
  player.play();



  // sample = new SoundFile(this, audioFile);
  // soundDuration = int(sample.duration() * 1000);
  // sample.play();

  // amplitude = new Amplitude(this);
  // fft = new FFT(this, bands);
  // analyzer = new AudioAnalyzer(sample);

  // startTime = millis();
  // endTime = startTime + soundDuration;
  // println("Start - End",startTime,endTime,soundDuration);
}


public void draw() {
  background(backgroundColor);

  stroke(255,255,255);
  drawWaveformsRect(0,0,width,height);

  if (debug) {
    drawDebugBar();
  }

  // Time
  // playTime = millis() - startTime;
  //println(playTime);

  // Analyse Audio
  // analyzer.analyze();

  // if (analyzer.isNormalizing()) {
  //   analyzer.drawBands();
  // }
  // else {
  //   analyzer.drawEqualizer();
  // }

  // END - save fft analyzer
  if ( player.position() >= player.length() ) {
    // analyzer.saveNormalizeData();
    exit();
  }
}

void drawDebugBar() {
  int barHeight = 50;
  noStroke();
  fill(0,0,0);
  rect(0,0,width,barHeight);
  fill(0,255,0);
  text( audioFile + " - " + timeFormat(player.position()) + " / " + timeFormat(player.length()), 10, barHeight/2 );
  // draw a line to show where in the song playback is currently located
  float posx = map(player.position(), 0, player.length(), 0, width);
  stroke(255,0,0);
  line(posx, 0, posx, barHeight);
  stroke(255,255,255);
  drawWaveformsRect(0,0,width,barHeight);
}

void drawWaveformsRect(int x, int y, int w, int h) {
  // draw the waveforms
  // the values returned by left.get() and right.get() will be between -1 and 1,
  // so we need to scale them up to see the waveform
  // note that if the file is MONO, left.get() and right.get() will return the same value
  int y1 = y + h/4;
  int y2 = y + h*3/4;
  int yh = h/2;
  for(int i = 0; i < player.bufferSize() - 1; i++)
  {
    float x1 = map( i, 0, player.bufferSize(), x, w );
    float x2 = map( i+1, 0, player.bufferSize(), x, w );
    line( x1, y1 + player.left.get(i)*yh, x2, y1 + player.left.get(i+1)*yh );
    line( x1, y2 + player.right.get(i)*yh, x2, y2 + player.right.get(i+1)*yh );
  }
}

void keyPressed()
{
  if (debug) {
    if (key==CODED) {
      if (keyCode == LEFT) {
        player.skip(-10000);
      } else if (keyCode == RIGHT) {
        player.skip(10000);
      }
    }
    else {
      if ( player.position() >= player.length() )
      {
        player.pause();
      }
      else {
        if ( player.isPlaying() )
        {
          player.pause();
        }
        else
        {
          player.play();
        }
      }
    }
  }
}

String timeFormat(int millis) {
  int seconds = millis / 1000;
  int minutes = seconds / 60;
  seconds -= minutes*60;
  millis -= (minutes*60) + (seconds*1000);
  return minutes +":"+ intFormat(seconds,2,"0");// +"."+ intFormat(millis,4,"0");
}

String intFormat(int value, int length, String ch) {
  String format = "";
  if (length>3 && value<1000) {
    format += ch;
  }
  if (length>2 && value<100) {
    format += ch;
  }
  if (length>1 && value<10) {
    format += ch;
  }
  return format + value;
}


// =============


// class AudioAnalyzer {

//   SoundFile sample;
//   float volume;
//   float[] volumeSpectrum = new float[bands]; //<>//
//   float[] smoothSpectrum = new float[bands];
//   float[] maxSpectrum = new float[bands];
//   float[] rmsSpectrum = new float[bands];
//   long rmsSamples = 0;
//   float[] normalizedFactor = new float[bands];
//   boolean isNormalizing = false;

//   AudioAnalyzer(SoundFile sound) {
//     sample = sound;
//     amplitude.input(sample);
//     fft.input(sample);
//     for(int i = 0; i < bands; i++){
//      smoothSpectrum[i] = 0.0;
//      maxSpectrum[i] = 0.0;
//      rmsSpectrum[i] = 0.0;
//      normalizedFactor[i] = 1.0;
//     }
//     loadNormalizeData();
//   }

//   void analyze() {
//     volume = amplitude.analyze();
//     fft.analyze(volumeSpectrum);
//     for(int i = 0; i < bands; i++){
//       // analyze
//       if (volumeSpectrum[i] > maxSpectrum[i]) { maxSpectrum[i]=volumeSpectrum[i]; }
//       rmsSpectrum[i] += volumeSpectrum[i] * volumeSpectrum[i];
//       rmsSamples++;
//       // map
//       volumeSpectrum[i] = volumeSpectrum[i] * normalizedFactor[i];
//       if (volumeSpectrum[i]>smoothSpectrum[i]) {
//         smoothSpectrum[i] += (volumeSpectrum[i] - smoothSpectrum[i]) * smoothingFactorUp;
//       }
//       else {
//         smoothSpectrum[i] += (volumeSpectrum[i] - smoothSpectrum[i]) * smoothingFactorDown;
//       }
//     }
//   }

//   boolean isNormalizing() {
//     return isNormalizing;
//   }

//   void drawBands() {
//     background(0,0,0);
//     textSize(32);
//     text("Analyzing "+bands+" FFT bands of `"+audioFile+"'.", 10, 30);
//     drawEqualizer();
//   }

//   void drawEqualizer() {
//     int padding = 10;
//     int barW = width / bands - padding * 2;
//     fill(255,0,0);
//     stroke(0,0,0);
//     for(int i = 0; i < bands; i++) {
//       rect( i*barW + padding , height + padding, barW - padding, height - padding - getSpectrumBandSmooth(i) * (height-padding) * 2 );
//     }
//   }

//   float getVolume() {
//     return volume;
//   }

//   float getVolumeSmooth() {
//     return volume;
//   }

//   float getSpectrumBand(int band) {
//     return volumeSpectrum[band];
//   }

//   float getSpectrumBandSmooth(int band) {
//     return smoothSpectrum[band];
//   }

//   void loadNormalizeData() {
//     File file = dataFile(getNormalizeFilename());
//     isNormalizing = !file.isFile();
//     if (!isNormalizing){
//      Table table;
//      table = loadTable("data/"+getNormalizeFilename(), "header");
//      if ( table.getRowCount() > 0 ) {
//        println(table.getRowCount() + " total rows in table");

//        for (TableRow row : table.rows()) {
//          int band = row.getInt("band");
//          float factor = row.getFloat("factor");
//          normalizedFactor[band] = factor;
//          // println("Band ",band," => ",normalizedFactor[band]);
//        }
//      }
//     }
//     else {
//       println("No normalize data => Analyzing now...");
//     }
//   }

//   void saveNormalizeData() {
//     float rmsFactor = 0.0;
//     Table table = new Table();
//     table.addColumn("band");
//     table.addColumn("max");
//     table.addColumn("rms");
//     table.addColumn("factor");

//     for(int i = 0; i < bands; i++) {
//       rmsFactor = sqrt(rmsSpectrum[i]/rmsSamples);
//       TableRow newRow = table.addRow();
//       newRow.setInt("band", i);
//       newRow.setFloat("max", maxSpectrum[i]);
//       newRow.setFloat("rms", rmsFactor);
//       newRow.setFloat("factor", 1/rmsFactor);
//     }
//     saveTable(table, "data/"+getNormalizeFilename());
//     println("Saved analyse");
//   }

//   String getNormalizeFilename() {
//     return "fft_analyze_"+bands+".csv";
//   }

// }



// class Shape {
//   float volume;
//   int hue;
//   float centerX, centerY, size;
//   float goalX, goalY, speedX,speedY;
//   float[] x = new float[formResolution];
//   float[] y = new float[formResolution];

//   Shape(int c) {
//     volume = 0.0;
//     hue = int(random(360));
//     centerX = width/2;
//     centerY = height/2;
//     size = 0;
//     float angle = radians(360/float(formResolution));
//     for (int i=0; i<formResolution; i++){
//       x[i] = cos(angle*i) * speedScale(size);
//       y[i] = sin(angle*i) * speedScale(size);
//     }
//     newGoal();
//   }

//   void newGoal() {
//     goalX = random(-width,width*2);
//     goalY = random(-width,width*2);
//     speedX = (goalX - centerX) / 10000;
//     speedY = (goalY - centerY) / 10000;
//   }

//   void setVolume(float set_volume) {
//     volume = set_volume;
//   }

//   void calcNewPosition() {
//     if (size>=0) {
//       centerX += speedScale(speedX);
//       centerY += speedScale(speedY);
//       speedX *= 1.01;
//       speedY *= 1.01;
//       size = abs(width/2 - centerX) / 300;

//       for (int i=0; i<formResolution; i++){
//         float step = stepSize * volume;
//         x[i] += random(-step,step);
//         y[i] += random(-step,step);
//       }

//       if ( size>width || (centerX < -size || centerX > width+size) && (centerY < -size || centerY > height+size ) ) {
//         centerX = width/2;
//         centerY = height/2;
//         size = 1;
//         newGoal();

//         // If near ending - don't draw anymore...
//         int now = millis();
//         float time = now - startTime;
//         float scale = 1;
//         if ( time > (soundDuration*1000-fadeInTime) ) {
//           size = -1;
//         }
//       }
//     }
//   }

//   void draw() {
//     if (size>=0) {
//       strokeWeight( 1+ size/50 * volume * 2);
//       stroke( hue-int(volume*30), 50+75*volume, size/2+25*volume, 30 + size/3);
//       fill( hue-int(volume*30), 50+50*volume, size+70*volume, 55 + size/3);
//       //noFill();

//       //for (int i=0; i<formResolution; i++){
//       //  line(centerX,centerY, scale(x[i])+centerX, scale(y[i])+centerY);
//       //}

//       // start controlpoint
//       beginShape();
//       curveVertex( scale(x[formResolution-1])+centerX, scale(y[formResolution-1])+centerY);
//       for (int i=0; i<formResolution; i++){
//         curveVertex(scale(x[i])+centerX, scale(y[i])+centerY);
//       }
//       curveVertex( scale(x[0])+centerX, scale(y[0])+centerY);
//       // end controlpoint
//       curveVertex( scale(x[1])+centerX, scale(y[1])+centerY);
//       endShape();
//     }
//   }

//   float speedScale(float speed) {
//     int now = millis();
//     float time = now - startTime;
//     float scale = 1;
//     if (time < fadeInTime) {
//       scale = time / fadeInTime;
//     }
//     if ( time > (soundDuration*1000-fadeInTime) ) {
//       scale = (soundDuration*1000 - time) / fadeInTime;
//     }
//     return speed * scale;
//   }

//   float scale(float pos) {
//     float scale = size;
//     return pos * scale;
//   }

// }
