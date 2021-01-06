/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "test.wav";

// Titles
String textLeft = "";
String textRight = "Visual: Jan den Besten";

// =========== DON'T CHANGE ANYTHING UNDER THIS LINE (or know what you do) =========== //

// Video
import com.hamoid.*;
float movieFPS = 30;
VideoExport videoExport;
boolean exportOn = true;

// Audio
import processing.sound.*;
SoundFile sample;
Amplitude rms;
float soundDuration = 0;
float ampFactor = 1.25;

// Visuals
float smoothingFactor = 0.75;
float sum;

// ScreenSizes
int padding;
int W;
int H;

// Shapes
int nrOfShapes = 50;
Shape[] shapes;

int formResolution = 2;
int stepSize = 3;
float speed = 0.04;
float initRadius = 15;



// Font
PFont lucida;

// Timing
int startTime = millis();
float textFadeTime = 1000.0;


/*

  SETUP

*/
public void setup() {
  size(1280,720);
  pixelDensity(2);
  colorMode(HSB, 360, 100, 100, 100);
  background(240,10,70);

  frameRate(movieFPS);
  randomSeed(1);

  // Global Sizes & Movement
  padding = 20;
  W = width - padding*2;
  H = height - padding*2;

  // Create random Shapes
  shapes = new Shape[nrOfShapes];
  for( int p=0; p<nrOfShapes; p++ ) {
    shapes[p] = new Shape(p);
    shapes[p].draw();
  }


  // Audio
  sample = new SoundFile(this, audioFile);
  soundDuration = sample.duration();
  sample.loop();
  rms = new Amplitude(this);
  rms.input(sample);

  // Video export
  if (exportOn) {
    videoExport = new VideoExport(this);
    videoExport.setFrameRate(movieFPS);
    videoExport.setQuality(70, 128);
    videoExport.setAudioFileName(audioFile);
    videoExport.setMovieFileName(audioFile + ".mp4");
    videoExport.startMovie();
  }

  infoText();
}

public void infoText() {
  float textOpacity = 100;
  textSize(20);
  textAlign(LEFT);
  fill(60,0,100,textOpacity);
  text(textLeft, padding, padding*2);
  textAlign(RIGHT);
  text(textRight, width-padding, padding*2);
}

public void draw() {
  //background(270,50,50);

  // Analyse audio & calc sizes
  sum += (rms.analyze()*ampFactor - sum) * smoothingFactor;

  // Loop shapes
  for( int p=0; p<nrOfShapes; p++ ) { //<>//
   shapes[p].setVolume(sum);
   shapes[p].calcNewPosition();
   shapes[p].draw();
  }


  // Export video
  if (exportOn) {
    videoExport.saveFrame();
    if(frameCount > round(movieFPS * soundDuration)) {
      videoExport.endMovie();
      exit();
    }
  }
  else {
    if(frameCount > round(movieFPS * soundDuration)) {
      exit();
    }
  }
}


// =============


class Shape {
  float volume;
  int hue;
  float centerX, centerY;
  float goalX, goalY;
  float[] x = new float[formResolution];
  float[] y = new float[formResolution];

  Shape(int c) {
    volume = 0;
    hue = (360/nrOfShapes) * (c+1);
    centerX = width/2;
    centerY = height/2;
    float angle = radians(360/float(formResolution));
    for (int i=0; i<formResolution; i++){
      x[i] = cos(angle*i) * initRadius;
      y[i] = sin(angle*i) * initRadius;
    }
    newGoal();
  }

  void newGoal() {
    float maxSize = initRadius * 75;
    goalX = centerX + random(-maxSize,maxSize);
    while (goalX<0) {
      goalX += maxSize;
    }
    while (goalX>width) {
      goalX -= maxSize;
    }

    goalY = centerY + random(-maxSize,maxSize);
    while (goalY<0) {
      goalY += maxSize;
    }
    while (goalY>height) {
      goalY -= maxSize;
    }
  }

  void setVolume(float set_volume) {
    volume = set_volume;
  }

  void calcNewPosition() {
    centerX += (goalX-centerX) * speed * volume/2;
    centerY += (goalY-centerY) * speed * volume/2;
    if ( abs(goalX - centerX) < 50 && abs(goalY - centerY) < 50 ) {
      newGoal();
    }

    for (int i=0; i<formResolution; i++){
      x[i] += random(-stepSize,stepSize);
      y[i] += random(-stepSize,stepSize);
    }
  }

  void draw() {
    stroke( hue-int(volume*30), 5+75*volume, 5+95*volume, 5+75*volume);
    strokeWeight(1+7*volume);
    //fill( hue-int(volume*30), 25+25*volume, 15+50*volume, 15);
    noFill();


    beginShape();
    // start controlpoint
    curveVertex(x[formResolution-1]+centerX, y[formResolution-1]+centerY);
    for (int i=0; i<formResolution; i++){
      curveVertex(x[i]+centerX, y[i]+centerY);
    }
    curveVertex(x[0]+centerX, y[0]+centerY);
    // end controlpoint
    curveVertex(x[1]+centerX, y[1]+centerY);
    endShape();
  }

} //<>//
