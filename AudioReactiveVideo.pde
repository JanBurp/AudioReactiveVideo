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
boolean exportOn = false;

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
int nrOfShapes = 50;
Shape[] shapes;

int formResolution = 3;
int stepSize = 10;
float speed = 1.5;
float initRadius = 70;

int startTime = millis();
int fadeInTime = 30000;


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

  fill(60-sum*240,10,30-sum*2,9);
  noStroke();
  rect(0,0,width,height);


  // Loop shapes
  for( int p=0; p<nrOfShapes; p++ ) { //<>// //<>//
   shapes[p].setVolume(sum);
   shapes[p].calcNewPosition();
   shapes[p].draw();
  }

  // shuffle
  //shuffle(sum);

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

//public void shuffle(float sum) {
//  if (sum>0.1) {
//    int w = int(random(10,width/2));
//    int h = int(random(10,height/2));
//    int hsize = width/4;
//    int vsize = height/4;
//    int x1 = int(random(0, width));
//    int y1 = int(random(0, height));
//    int x2 = round(x1 + w);
//    int y2 = round(y1 + h);
//    copy(x1, y1, w, h, x2, y2, w, h);
//  }
//}


// =============


class Shape {
  float volume;
  int hue;
  float centerX, centerY, size;
  float goalX, goalY, speedX,speedY;
  float[] x = new float[formResolution];
  float[] y = new float[formResolution];

  Shape(int c) {
    volume = 0.0;
    hue = int(random(360));
    centerX = width/2;
    centerY = height/2;
    size = 0;
    float angle = radians(360/float(formResolution));
    for (int i=0; i<formResolution; i++){
      x[i] = cos(angle*i) * speedScale(size);
      y[i] = sin(angle*i) * speedScale(size);
    }
    newGoal();
  }

  void newGoal() {
    goalX = random(-width,width*2);
    goalY = random(-width,width*2);
    speedX = (goalX - centerX) / 10000;
    speedY = (goalY - centerY) / 10000;
  }

  void setVolume(float set_volume) {
    volume = set_volume;
  }

  void calcNewPosition() {
    if (size>=0) {
      centerX += speedScale(speedX);
      centerY += speedScale(speedY);
      speedX *= 1.01;
      speedY *= 1.01;
      size = abs(width/2 - centerX) / 300;

      for (int i=0; i<formResolution; i++){
        float step = stepSize * volume;
        x[i] += random(-step,step);
        y[i] += random(-step,step);
      }

      if ( size>width || (centerX < -size || centerX > width+size) && (centerY < -size || centerY > height+size ) ) {
        centerX = width/2;
        centerY = height/2;
        size = 1;
        newGoal();

        // If near ending - don't draw anymore...
        int now = millis();
        float time = now - startTime;
        float scale = 1;
        if ( time > (soundDuration*1000-fadeInTime) ) {
          size = -1;
        }
      }
    }
  }

  void draw() {
    if (size>=0) {
      strokeWeight( 1+ size/50 * volume * 2);
      stroke( hue-int(volume*30), 50+75*volume, size/2+25*volume, 30 + size/3);
      fill( hue-int(volume*30), 50+50*volume, size+70*volume, 55 + size/3);
      //noFill();

      //for (int i=0; i<formResolution; i++){
      //  line(centerX,centerY, scale(x[i])+centerX, scale(y[i])+centerY);
      //}

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
  }

  float speedScale(float speed) {
    int now = millis();
    float time = now - startTime;
    float scale = 1;
    if (time < fadeInTime) {
      scale = time / fadeInTime;
    }
    if ( time > (soundDuration*1000-fadeInTime) ) {
      scale = (soundDuration*1000 - time) / fadeInTime;
    }
    return speed * scale;
  }

  float scale(float pos) {
    float scale = size;
    return pos * scale;
  }

}
