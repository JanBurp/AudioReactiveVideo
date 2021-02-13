/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "test.wav";


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
float ampFactor = 1.5;

// Visuals
float smoothingFactor = 1;
float sum;

// ScreenSizes
int padding;
int W;
int H;

// Shapes
int nrOfShapes = 25;
Shape[] shapes;

int formResolution = 5;
int stepSize = 7;
float speed = 0.5;
float initRadius = 100;

int startTime = millis();
int fadeInTime = 150000;


/*

  SETUP

*/
public void setup() {
  size(1280,720,P2D);
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

}

public void draw() {
  // Analyse audio & calc sizes
  sum += (rms.analyze()*ampFactor - sum) * smoothingFactor;

  background(240-sum*10,10,40-sum*2,0.1);

  // Loop shapes
  for( int p=0; p<nrOfShapes; p++ ) { //<>// //<>//
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
  float centerX, centerY, size;
  float speedX, speedY;
  float[] x = new float[formResolution];
  float[] y = new float[formResolution];

  Shape(int c) {
    volume = 0.0;
    hue = int(random(360));
    centerX = width/2;
    centerY = height/2;
    size = 10 + float(c*3/nrOfShapes) * initRadius  ;
    float angle = radians(360/float(formResolution));
    for (int i=0; i<formResolution; i++){
      x[i] = cos(angle*i) * size;
      y[i] = sin(angle*i) * size;
    }
    newGoal();
  }

  void newGoal() {
    float maxSpeed = float(width)/1000000 * (size/initRadius/2);
    speedX = random(-maxSpeed,maxSpeed);
    maxSpeed = float(height)/1000000;
    speedY = random(-maxSpeed,maxSpeed);
  }

  void setVolume(float set_volume) {
    volume = set_volume;
  }

  void calcNewPosition() {
    centerX += speedX * scale(volume*10000);
    centerY += speedY * scale(volume*10000);

    float boundary = initRadius*3;

    if ( centerX>width+boundary) {
      centerX = -boundary;
    }
    if ( centerX<-boundary ) {
      centerX = width+boundary;
    }
    if ( centerY>height+boundary) {
      centerY = -boundary;
    }
    if (centerY<-boundary ) {
      centerY = height + boundary;
    }

    for (int i=0; i<formResolution; i++){
      float step = stepSize * volume;
      x[i] += random(-step,step);
      y[i] += random(-step,step);
    }
  }

  void draw() {
    strokeWeight( 1+ size/50 * volume);
    stroke( hue-int(volume*30), 5+75*volume, scale(size/10+15*volume), 70);
    fill( hue-int(volume*30), 5+50*volume, scale(size/3+50*volume), 75);
    //noFill();


    for (int i=0; i<formResolution; i++){
      //curveVertex(centerX,centerY);
      //curveVertex(scale(x[i])+centerX, scale(y[i])+centerY);
      line(centerX,centerY, scale(x[i])+centerX, scale(y[i])+centerY);
    }

    // start controlpoint
    beginShape();
    curveVertex( scale(x[formResolution-1])+centerX, scale(y[formResolution-1])+centerY);
    for (int i=0; i<formResolution; i++){
      curveVertex(scale(x[i])+centerX, scale(y[i])+centerY);
    }
    curveVertex( scale(x[0])+centerX, scale(y[0])+centerY);
    // end controlpoint
    curveVertex( scale(x[1])+centerX, scale(y[1])+centerY);
    endShape();
  }

  float scale(float pos) {
    float scale = 1.0;
    int now = millis();
    float time = now - startTime;
    if (time < fadeInTime) {
      scale = time / fadeInTime;
    }
    if ( time > (soundDuration*1000-fadeInTime) ) {
      scale = (soundDuration*1000 - time) / fadeInTime;
    }
    return pos * scale;
  }

}
