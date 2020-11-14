String audioFile = "demo.wav";
float soundDuration = 0;

String textLeft = "Audio Reactive Visuals";
String textRight = "by: Jan den Besten";




import com.hamoid.*;
float movieFPS = 30;
VideoExport videoExport;

// Declare the processing sound variables
import processing.sound.*;
SoundFile sample;
Amplitude rms;

float smoothingFactor = 0.1;
float sum;

// Sizes
int padding;
int W;
int H;
int halfH;

// Text
PFont lucida;
int startTime = millis();
float textFadeTime = 1000.0;


public void setup() {
  size(1280,720);
  background(255);
  frameRate(movieFPS);

  padding = width/20;
  W = width - padding*2;
  H = height;
  halfH = height/2;

  //Load and play a soundfile and loop it
  sample = new SoundFile(this, audioFile);
  soundDuration = sample.duration();
  sample.loop();

  // Create and patch the rms tracker
  rms = new Amplitude(this);
  rms.input(sample);

  randomSeed(0);

  videoExport = new VideoExport(this);
  videoExport.setFrameRate(movieFPS);
  videoExport.setQuality(70, 128);
  videoExport.setAudioFileName(audioFile);
  videoExport.setMovieFileName(audioFile + ".mp4");
  videoExport.startMovie();
}



public void infoText() {
  float textOpacity = 100;
  float playTime = float(millis() - startTime);

  // Fade out at start
  textOpacity = (textFadeTime / playTime) * 100;

  // At the end -  fade in
  if(frameCount > round(movieFPS * (soundDuration - textFadeTime/1000)) ) {
    textOpacity = ( textFadeTime / (playTime - soundDuration*1000) ) * 100;
  }


  textSize(20);
  textAlign(LEFT);
  text(textLeft, padding, H-padding);
  fill(110,110,110,textOpacity);

  textAlign(RIGHT);
  text(textRight, width-padding, H-padding);
  fill(110,110,110,textOpacity);

}


public void draw() {
  background(255);

  int gap = int( sqrt(random(2,200)) );

  for (int x=1; x<(W); x=x+gap) {

    // smooth the rms data by smoothing factor
    sum += (rms.analyze() - sum) * smoothingFactor;

    // rms.analyze() return a value between 0 and 1. It's
    // scaled to halfH and then multiplied by a fixed scale factor
    float rms_scaled = sum * (H/2);

    float shape = sin( float(x)/float(W) * PI);
    rms_scaled = rms_scaled * shape;

    int left = x+padding;

    strokeWeight(2);
    stroke(70,10,10);
    point( left, halfH - rms_scaled);
    point( left, halfH + rms_scaled);

    strokeWeight(1);
    stroke(100,100,100, 100);
    line( left, halfH - rms_scaled,  left, halfH + rms_scaled);

  }

  infoText();

  videoExport.saveFrame();
  // End when we have exported enough frames
  // to match the sound duration.
  if(frameCount > round(movieFPS * soundDuration)) {
    videoExport.endMovie();
    exit();
  }

}
