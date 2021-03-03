/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

boolean debug = false;

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "Zaagstof-drang.wav";

// Basic colors
color backgroundColor = color(220,220,220);

// Timing (milliseconds)
int outTroTime  = 12000;
int fadeOutTime = 5000;
//
int outTroStartTime = -1;

// Objects
CircleWave ampCircles[];
// LineWave lines[];
// int nrOflines = 100;
// int currentLine = 0;


// =========== DON'T CHANGE ANYTHING UNDER THIS LINE (or know what you do) =========== //

// Time
int startTime = millis();

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

  startTime = millis();
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


  // Time
  if ( (player.length()-player.position()) <= outTroTime ) {
    outTro();
  }

  // DEBUG
  if (debug) {
    drawDebugBar();
  }

  // END - save fft analyzer & EXIT
  if ( player.position() >= player.length() ) {
    if (outTroStartTime<0) {
      outTroStartTime = millis();
    }
    if (fadeOut()) {
      if (analyzer.isNormalizing()) {
        analyzer.saveNormalizeData();
      }
      exit();
    }
  }
}

void drawDebugBar() {
  int barHeight = 50;
  noStroke();
  fill(0,0,0,50);
  rect(0,0,width,barHeight);
  fill(0,255,0);
  textSize(12);
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


void outTro() {
  PFont font;
  font = createFont("Lucida Sans Unicode.ttf", 70, true);
  textFont(font);
  textAlign(CENTER);
  int sceneTime = outTroTime - (player.length() - player.position());
  float opacity = float(sceneTime) / float(outTroTime) * 100;
  fill(220,220,220, opacity);
  text( "Music: Zaagstof", width/2, height/2 - 100);
  text( "Visuals: Jan den Besten", width/2, height/2 + 100 );
}

boolean fadeOut() {
  int sceneTime = millis() - outTroStartTime;
  if (sceneTime > fadeOutTime) {
    return true;
  }
  float amount = float(sceneTime) / float(fadeOutTime) * 100;
  fill(100,100,100,amount);
  noStroke();
  rect(0,0,width, height);
  return false;
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
    }
  }

  void drawWaveformsRect(int x, int y, int w, int h) {
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
         // println("Band ",band," => ",max,rmsSpectrum[band],normalizedFactor[band],maxedFactor[band]);
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
    x += xPlus;
    while (x>width) {
      x -= width;
    }
    while ( x<0 ) {
      x += width;
    }
    int yPlus = int(random(-max,max));
    y += yPlus;
    while (y>height) {
      y -= height;
    }
    while ( y<0 ) {
      y += height;
    }
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
      stroke(110,55,55,20);
      fill(220,0,0,7);
    }
    if (leftOrRight==0) {
      stroke(110,110,55,20);
      fill(220,220,0,7);
    }
    if (leftOrRight>0) {
      stroke(55,55,110,20);
      fill(0,0,220,7);
    }
    beginShape();
    for(int i = 0; i < steps; i++) {
      vertex( xc[i],yc[i] );
    }
    endShape();

  }

}


// class LineWave {

//   int steps;
//   float[] points;
//   int y = height/2;
//   int yDiff = 50;
//   int ySpeed = 5;

//   LineWave() {
//     steps = player.bufferSize() - 1;
//     points = new float[steps];
//     calcPoints();
//   }

//   void calcPoints() {
//     for(int i = 0; i < steps; i++)
//     {
//       points[i] = player.mix.get(i);
//     }
//   }

//   void draw() {
//     stroke(0,0,0);
//     for(int i = 1; i < steps; i++)
//     {
//       float x1 = map( i, 0, steps, 0, width );
//       float x2 = map( i+1, 0, steps, 0, width );
//       line( x1, y - points[i-1]*yDiff, x2, y - points[i]*yDiff );
//     }
//     y += ySpeed;
//     if (y > height) {
//       y = height/2;
//       calcPoints();
//     }
//   }
// }


