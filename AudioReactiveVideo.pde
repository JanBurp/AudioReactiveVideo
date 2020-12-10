/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "test.wav";

// Titles
String textLeft = "Audio Reactive Visuals";
String textRight = "by: Jan den Besten";

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
float ampFactor = 1.25;

// Visuals
float smoothingFactor = 0.75;
float sum;

// ScreenSizes
int padding;
int W;
int H;
PVector gravity;

// Points
int nrOfPoints = 100;
int minRadius = 5;
int maxRadius = 25;
int maxSpeed = 25;
Point[] points;


// Font
PFont lucida;

// Timing
int startTime = millis();
float textFadeTime = 1000.0;


/*

  SETUP

*/
public void setup() {
  size(1280,720,P2D);
  pixelDensity(2);
  colorMode(HSB, 360, 100, 100, 100);
  background(30,30,30);

  frameRate(movieFPS);
  randomSeed(0);

  // Global Sizes & Movement
  padding = 20;
  W = width - padding*2;
  H = height - padding*2;
  gravity = new PVector( 0, -.05 );

  // Create random points
  points = new Point[nrOfPoints];
  for( int p=0; p<nrOfPoints; p++ ) {
    points[p] = new Point();
    points[p].draw();
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
  
  // show text
  infoText();

}



/*

  Display tekst

 */
public void infoText() {
  float textOpacity = 100;
  textSize(20);

  textAlign(LEFT);
  fill(60,50,100,textOpacity);
  text(textLeft, padding, padding*2);
  textAlign(RIGHT);
  text(textRight, width-padding, padding*2);
}

/*

  Draw frame

*/
public void draw() {
  //background(270,50,50);

  // Analyse audio & calc sizes
  sum += (rms.analyze()*ampFactor - sum) * smoothingFactor;

  // Loop points
  for( int p=0; p<nrOfPoints; p++ ) {
    points[p].setVolume(sum);
    points[p].calcNewPosition();
    points[p].draw();
    points[p].checkBoundaryCollision();
    for(int o=0; o<nrOfPoints; o++) {
      if (p!=o) {
        points[p].checkCollision(points[o]);
      }
    }
  }
  // Curve ?
  for( int p=0; p<nrOfPoints; p++ ) {

  }


  float playTime = float(millis() - startTime);

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

class Point {
  PVector position;
  PVector velocity;
  float volume;
  float initRadius;
  int radius;
  float m;

  Point() {
    position = new PVector( int(random(width)), int(random(height)) );
    velocity = new PVector( random(maxSpeed*2)-maxSpeed, random(maxSpeed*2)-maxSpeed );
    volume = 0;
    initRadius = random(minRadius,minRadius+2);
    radius = int(initRadius);
    m = radius * .1;
  }

  void setVolume(float set_volume) {
    volume = set_volume;
    radius = int(initRadius + (set_volume/1*maxRadius));
    m = radius * .1;
  }

  void calcNewPosition() {
    position.x += velocity.x * volume;
    position.y += velocity.y;
    velocity.add(gravity);
  }

  void checkBoundaryCollision() {
    if (position.x > width-radius) {
      position.x = width-radius;
      velocity.x *= -1;
    } else if (position.x < radius) {
      position.x = radius;
      velocity.x *= -1;
    //} else if (position.y > height-radius) {
    //  position.y = height-radius;
    //  velocity.y *= -0.7;
    } else if (position.y < radius) {
       position.y = radius;
       velocity.y *= -0.9;
    }
  }

  void checkCollision(Point other) {
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.position, position);
    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();
    // Minimum distance before they are touching
    float minDistance = radius + other.radius;

    if (distanceVectMag < minDistance) {
      float distanceCorrection = (minDistance-distanceVectMag)/2.0;
      PVector d = distanceVect.copy();
      PVector correctionVector = d.normalize().mult(distanceCorrection);
      other.position.add(correctionVector);
      position.sub(correctionVector);

      // get angle of distanceVect
      float theta  = distanceVect.heading();
      // precalculate trig values
      float sine = sin(theta);
      float cosine = cos(theta);

      /* bTemp will hold rotated ball positions. You
       just need to worry about bTemp[1] position*/
      PVector[] bTemp = {
        new PVector(), new PVector()
      };

      /* this ball's position is relative to the other
       so you can use the vector between them (bVect) as the
       reference point in the rotation expressions.
       bTemp[0].position.x and bTemp[0].position.y will initialize
       automatically to 0.0, which is what you want
       since b[1] will rotate around b[0] */
      bTemp[1].x  = cosine * distanceVect.x + sine * distanceVect.y;
      bTemp[1].y  = cosine * distanceVect.y - sine * distanceVect.x;

      // rotate Temporary velocities
      PVector[] vTemp = {
        new PVector(), new PVector()
      };

      vTemp[0].x  = cosine * velocity.x + sine * velocity.y;
      vTemp[0].y  = cosine * velocity.y - sine * velocity.x;
      vTemp[1].x  = cosine * other.velocity.x + sine * other.velocity.y;
      vTemp[1].y  = cosine * other.velocity.y - sine * other.velocity.x;

      /* Now that velocities are rotated, you can use 1D
       conservation of momentum equations to calculate
       the final velocity along the x-axis. */
      PVector[] vFinal = {
        new PVector(), new PVector()
      };

      // final rotated velocity for b[0]
      vFinal[0].x = ((m - other.m) * vTemp[0].x + 2 * other.m * vTemp[1].x) / (m + other.m);
      vFinal[0].y = vTemp[0].y;

      // final rotated velocity for b[0]
      vFinal[1].x = ((other.m - m) * vTemp[1].x + 2 * m * vTemp[0].x) / (m + other.m);
      vFinal[1].y = vTemp[1].y;

      // hack to avoid clumping
      bTemp[0].x += vFinal[0].x;
      bTemp[1].x += vFinal[1].x;

      /* Rotate ball positions and velocities back
       Reverse signs in trig expressions to rotate
       in the opposite direction */
      // rotate balls
      PVector[] bFinal = {
        new PVector(), new PVector()
      };

      bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
      bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
      bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
      bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

      // update balls to screen position
      other.position.x = position.x + bFinal[1].x;
      other.position.y = position.y + bFinal[1].y;

      position.add(bFinal[0]);

      // update velocities
      velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
      velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
      other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
      other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
    }
  }


  void draw() {
    if (position.x>0 && position.x<width && position.y>0 && position.y<height) {
      int hue = 312 - int( volume*338 );
      strokeWeight( int(float(radius)/float(maxRadius) * 7 ));
      stroke(hue,70,78,70 - volume*60);
      fill(hue,80,60,60 - volume*54);
      circle(position.x,position.y,radius);
    }
  }

}
