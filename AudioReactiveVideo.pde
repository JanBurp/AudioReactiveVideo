/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

boolean debug = false;

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "Zaagstof-drang.wav";

// Basic colors
color backgroundColor = color(220,220,220);

// Timing
int fadeInTime = 30000;
int fadeOutTime = 30000;

// Scenes


// Objects
CircleWave ampCircles[];
LineWave lines[];
int nrOflines = 100;
int currentLine = 0;


// =========== DON'T CHANGE ANYTHING UNDER THIS LINE (or know what you do) =========== //

// Time
int startTime = millis();
int endTime = 0; // will be startTime + duration of soundfile
int playTime = 0;


// Audio
import ddf.minim.analysis.*;
import ddf.minim.*;
Minim minim;
AudioPlayer player;
FFT         fft;
BeatDetect  beat;
AudioAnalyzer analyzer;

float smoothingFactorUp = 0.8;
float smoothingFactorDown = 0.1;


/*

  SETUP

*/
public void setup() {
  // size(1280,720,P2D);
  fullScreen(P2D);
  pixelDensity(2);
  background(backgroundColor);

  randomSeed(1);

  // Start Audio
  minim = new Minim(this);
  player = minim.loadFile( audioFile );
  player.play();

  // Analyzer
  analyzer = new AudioAnalyzer();
  beat = new BeatDetect(player.bufferSize(), player.sampleRate());
  beat.setSensitivity(300);

  // Graphics
  ampCircles = new CircleWave[3];
  ampCircles[0] = new CircleWave(width/4,height/2,height/2,-1);
  ampCircles[1] = new CircleWave(width/2,height/2,height/2,0);
  ampCircles[2] = new CircleWave(width/4*3,height/2,height/2,1);

  // lines = new LineWave[nrOflines];
  // for(int i = 0; i < nrOflines; i++) {
  //   lines[i] = new LineWave();
  // }
}


public void draw() {
  analyzer.analyze();

  beat.detect(player.mix);

  if (beat.isKick()) {
    ampCircles[0].move();
  }
  if (beat.isHat()) {
    ampCircles[1].move();
  }
  if (beat.isSnare()) {
    ampCircles[2].move();
  }

  // background(backgroundColor);
  // stroke(255,255,255);

  // analyzer.drawWaveformsRect(0,0,width,height);
  // analyzer.drawEqualizer(0,height,width,height);

  // Graphics
  ampCircles[0].draw();
  ampCircles[1].draw();
  ampCircles[2].draw();

  // lines[currentLine].draw();
  // currentLine++;
  // if (currentLine>=nrOflines) {
  //   currentLine = 0;
  // }

  // DEBUG
  if (debug) {
    drawDebugBar();
  }

  // END - save fft analyzer & EXIT
  if ( player.position() >= player.length() ) {
    if (analyzer.isNormalizing()) {
      analyzer.saveNormalizeData();
    }
    exit();
  }
}

void drawDebugBar() {
  int barHeight = 50;
  noStroke();
  fill(0,0,0,50);
  rect(0,0,width,barHeight);
  fill(0,255,0);
  text( audioFile + " - " + timeFormat(player.position()) + " / " + timeFormat(player.length()), 10, barHeight/2 );

  if (analyzer.isNormalizing()) {
    text( "ANALYZING", width/2, barHeight/2 );
  }

  // draw a line to show where in the song playback is currently located
  float posx = map(player.position(), 0, player.length(), 0, width);
  stroke(255,0,0);
  line(posx, 0, posx, barHeight);
  stroke(255,255,255);

  analyzer.drawWaveformsRect(0,0,width,barHeight);
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


class AudioAnalyzer {

  int bands = 0;
  float volume = 0.0;
  float smoothVolume = 0.0;
  float[] volumeSpectrum;
  float[] smoothSpectrum;
  float[] maxSpectrum;
  float[] rmsSpectrum;
  float[] normalizedFactor;
  float[] maxedFactor;
  long rmsSamples = 0;
  boolean isNormalizing = false;

  AudioAnalyzer() {
    fft = new FFT( player.bufferSize(), player.sampleRate() );
    fft.logAverages( 33, 1 );
    bands = fft.avgSize();

    volumeSpectrum = new float[bands];
    smoothSpectrum = new float[bands];
    maxSpectrum = new float[bands];
    rmsSpectrum = new float[bands];
    maxedFactor = new float[bands];
    normalizedFactor = new float[bands];

    for(int i = 0; i < bands; i++){
     smoothSpectrum[i] = 0.0;
     maxSpectrum[i] = 0.0;
     rmsSpectrum[i] = 0.0;
     maxedFactor[i] = 1.0;
     normalizedFactor[i] = 1.0;
    }

    loadNormalizeData();
  }

  void analyze() {
    volume = player.mix.level();
    // Smoothing
    if (volume>smoothVolume) {
      smoothVolume += (volume - smoothVolume) * smoothingFactorUp;
    }
    else {
      smoothVolume += (volume - smoothVolume) * smoothingFactorDown;
    }

    // FFT
    fft.forward( player.mix );
    for(int i = 0; i < bands; i++){
      volumeSpectrum[i] = fft.getAvg(i);

      // analyze
      if (isNormalizing) {
        if (volumeSpectrum[i] > maxSpectrum[i]) { maxSpectrum[i]=volumeSpectrum[i]; }
        rmsSpectrum[i] += volumeSpectrum[i] * volumeSpectrum[i];
        rmsSamples++;
        println(rmsSamples);
      }
      else {
        // Factor
        if (volumeSpectrum[i]>=(rmsSpectrum[i]/2) ) {
          volumeSpectrum[i] = volumeSpectrum[i] * maxedFactor[i];
        }
        else {
          volumeSpectrum[i] = volumeSpectrum[i] * normalizedFactor[i];
        }
      }

      // Smoothing
      if (volumeSpectrum[i]>smoothSpectrum[i]) {
        smoothSpectrum[i] += (volumeSpectrum[i] - smoothSpectrum[i]) * smoothingFactorUp;
      }
      else {
        smoothSpectrum[i] += (volumeSpectrum[i] - smoothSpectrum[i]) * smoothingFactorDown;
      }

    }
  }

  boolean isNormalizing() {
    return isNormalizing;
  }

  void drawEqualizer(int x, int y, int w, int h) {
    stroke(255,0,0);

    int bandwidth = width/bands;
    for(int i = 0; i < bands; i++)
    {
      noFill();
      stroke(0,0,0);
      rect( i*bandwidth, 0, bandwidth, height);

      fill(255,0,0);
      rect( i*bandwidth, height, bandwidth, -height * smoothSpectrum[i] );

      // fill(0,255,0);
      // text( i+" - "+ round(smoothSpectrum[i]*100), i*bandwidth, height-20 );
    }
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


  float getVolume() {
    return volume;
  }

  float getVolumeSmooth() {
    return smoothVolume;
  }

  float getSpectrumBand(int band) {
    return volumeSpectrum[band];
  }

  float getSpectrumBandSmooth(int band) {
    return smoothSpectrum[band];
  }

  void loadNormalizeData() {
    File file = dataFile(getNormalizeFilename());
    isNormalizing = !file.isFile();
    if (!isNormalizing){
     Table table;
     table = loadTable("data/"+getNormalizeFilename(), "header");
     if ( table.getRowCount() > 0 ) {
       println(table.getRowCount() + " total rows in table");

       for (TableRow row : table.rows()) {
         int band = row.getInt("band");
         float max = row.getFloat("max");
         float rms = row.getFloat("rms");
         rmsSpectrum[band] = rms;
         maxedFactor[band] = 1/max;
         normalizedFactor[band] = 1/rms;
         println("Band ",band," => ",max,rmsSpectrum[band],normalizedFactor[band],maxedFactor[band]);
       }
     }
    }
    else {
      println("No normalize data => Analyzing now...");
    }
  }

  void saveNormalizeData() {
    float rmsFactor = 0.0;
    Table table = new Table();
    table.addColumn("band");
    table.addColumn("max");
    table.addColumn("rms");

    for(int i = 0; i < bands; i++) {
      rmsFactor = sqrt(rmsSpectrum[i]/rmsSamples);
      TableRow newRow = table.addRow();
      newRow.setInt("band", i);
      newRow.setFloat("max", maxSpectrum[i]);
      newRow.setFloat("rms", rmsFactor);
    }
    saveTable(table, "data/"+getNormalizeFilename());
    println("Saved analyse");
  }

  String getNormalizeFilename() {
    return "fft_analyze_"+bands+".csv";
  }

}


class CircleWave {

  int x, y, size, leftOrRight;

  CircleWave(int x, int y,int size,int leftOrRight) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.leftOrRight = leftOrRight;
  }

  void move() {
    int max = size/4;
    int xPlus = int(random(-max,max));
    if (x>width) {
      xPlus = int(random(-max,0));
    }
    if (x<0) {
      xPlus = int(random(0,max));
    }
    x += xPlus;
    int yPlus = int(random(-max,max));
    if (y>height) {
      yPlus = int(random(-max,0));
    }
    if (y<0) {
      yPlus = int(random(0,max));
    }
    y += yPlus;
  }

  void draw() {
    int steps = player.bufferSize() - 1;
    float angleStep = 2*PI / steps;
    int[] xc = new int[steps];
    int[] yc = new int[steps];

    for(int i = 0; i < steps; i++)
    {
      float volume = 0.0;
      if (leftOrRight<0) {
        volume = player.left.get(i);
      }
      if (leftOrRight==0) {
        volume = player.mix.get(i);
      }
      if (leftOrRight>0) {
        volume = player.right.get(i);
      }
      float angle = angleStep * i;
      float radius = size * abs(volume*2);
      xc[i] = int(x + sin(angle) * radius);
      yc[i] = int(y + cos(angle) * radius);
    }


    if (leftOrRight<0) {
      stroke(110,0,0,10);
      fill(220,0,0,10);
    }
    if (leftOrRight==0) {
      stroke(110,110,0,10);
      fill(220,220,0,10);
    }
    if (leftOrRight>0) {
      stroke(0,0,110,10);
      fill(0,0,220,10);
    }
    beginShape();
    for(int i = 0; i < steps; i++) {
      // line( xc[i-1],yc[i-1], xc[i],yc[i]);
      vertex( xc[i],yc[i] );
    }
    endShape();

  }

}


class LineWave {

  int steps;
  float[] points;
  int y = height/2;
  int yDiff = 50;
  int ySpeed = 5;

  LineWave() {
    steps = player.bufferSize() - 1;
    points = new float[steps];
    calcPoints();
  }

  void calcPoints() {
    for(int i = 0; i < steps; i++)
    {
      points[i] = player.mix.get(i);
    }
  }

  void draw() {
    stroke(0,0,0);
    for(int i = 1; i < steps; i++)
    {
      float x1 = map( i, 0, steps, 0, width );
      float x2 = map( i+1, 0, steps, 0, width );
      line( x1, y - points[i-1]*yDiff, x2, y - points[i]*yDiff );
    }
    y += ySpeed;
    if (y > height) {
      y = height/2;
      calcPoints();
    }
  }
}



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
