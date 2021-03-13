/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

// Define you're scenes and audio in Scenes.pde


PFont font;

/*
  SETUP
*/
public void setup() {
  randomSeed(1);
  size(1280,720,P2D);
  pixelDensity(2);
  colorMode(RGB, 255,255,255,100);
  background(220,220,220);
  font = createFont("Lucida Sans Unicode.ttf", 70, true);

  // Start Audio
  minim = new Minim(this);
  player = minim.loadFile( audioFile );
  player.play();

  // Start Analyzer
  analyzer = new AudioAnalyzer();
  beat = new BeatDetect(player.bufferSize(), player.sampleRate());
  beat.setSensitivity(300);

  setupScenes();
}


public void draw() {
  background(220,220,220);
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

  // analyzer.drawWaveformsRect(0,0,width,height);
  // analyzer.drawEqualizer(0,height,width,height);

  drawScenes();

  // DEBUG
  if (debug) {
    drawDebugBar();
  }

  // END - save fft analyzer & EXIT
  if ( player.position() >= player.length()) {
    if (analyzer.isNormalizing()) {
      analyzer.saveNormalizeData();
    }
    exit();
  }
}
