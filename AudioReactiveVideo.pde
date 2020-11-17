/*
  A tool to create instant visuals reacting on an audiofile
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
// Audio
import processing.sound.*;
SoundFile sample;
Amplitude rms;
float soundDuration = 0;

// Visuals
float smoothingFactor = 0.1;
float sum;

// Sizes
int padding;
int W;
int H;
int halfH;

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
  background(0);
  frameRate(movieFPS);

  padding = width/20;
  W = width - padding*2;
  H = height;
  halfH = height/2;

  // Audio
  sample = new SoundFile(this, audioFile);
  soundDuration = sample.duration();
  sample.loop();
  rms = new Amplitude(this);
  rms.input(sample);

  // Video export
  videoExport = new VideoExport(this);
  videoExport.setFrameRate(movieFPS);
  videoExport.setQuality(70, 128);
  videoExport.setAudioFileName(audioFile);
  videoExport.setMovieFileName(audioFile + ".mp4");
  videoExport.startMovie();

  randomSeed(0);
}



/*

  Display tekst

 */
public void infoText() {
  float textOpacity = 100;
  float playTime = float(millis() - startTime);
  // Fade out at start
  textOpacity = (textFadeTime / playTime) * 100;
  // Fade in near end
  if(frameCount > round(movieFPS * (soundDuration - textFadeTime/1000)) ) {
    textOpacity = ( textFadeTime / (playTime - soundDuration*1000) ) * 100;
  }
  textSize(20);
  textAlign(LEFT);
  text(textLeft, padding, H-padding);
  fill(255,255,255,textOpacity);
  textAlign(RIGHT);
  text(textRight, width-padding, H-padding);
  fill(255,255,255,textOpacity);
}

/*

  Draw frame

*/
public void draw() {
  background(0);

  // random gap
  int gap = int( sqrt(random(2,200)) );

  for (int x=1; x<(W); x=x+gap) {
    // calculate points
    sum += (rms.analyze() - sum) * smoothingFactor;
    float rms_scaled = sum * (H/2);
    float shape = sin( float(x)/float(W) * PI);
    rms_scaled = rms_scaled * shape;
    int left = x+padding;
    // draw points
    strokeWeight(5);
    stroke(200,10,10);
    point( left, halfH - rms_scaled);
    point( left, halfH + rms_scaled);
    // draw line
    strokeWeight(1);
    stroke(255,255,255, 170);
    line( left, halfH - rms_scaled,  left, halfH + rms_scaled);
  }

  // show text
  infoText();

  // Export video
  videoExport.saveFrame();
  // End?
  if(frameCount > round(movieFPS * soundDuration)) {
    videoExport.endMovie();
    exit();
  }

}
