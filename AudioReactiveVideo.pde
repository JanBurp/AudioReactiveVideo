/*

  A tool to create visuals reacting on an audiofile (c) Jan den Besten.

  Purpose of .pde files:
  - This file - Configuration and basic setup
  - Core.pde - All core classes and methods. Don't touch it.
  - CoreScenes.pde - Example scenes. You can use them, change them, copy them as you like.
  - scene###.pde - More (example) scenes, create you're own.

 */


/* ================ CONFIGURATION ========================== */

/*
  Put you're audio file (.wav) in the 'data' folder and fill in the name:
 */
String audioFile = "test_loop.wav";


/*
  If this is true, the sketch will start with a pauze button. Pressing SPACEBAR will start audio and the sketch.
  Handy when making a screenrecording.
 */
boolean startWithPauzeButton = false;



/*
  Declare you're scenes here.
  Best practice is to use a new .pde file for every scene with a name of 'scene####.pde'
  You can find some examples in CoreScenes.pde
 */
Scene scenes[] = {
  new waveLandscapeTrigger(),
  new coreOutro(),
  new coreFadeOut(),
};




int backgroundRedraw = 4;
int backgroundTimer = 0;



/*
  Global setup method
 */
public void setup() {
  // Setup graphics
  size(1280,720,P2D);
  pixelDensity(2);
  colorMode(RGB, 255,255,255,100);
  resetBackground(true);
  backgroundTimer = backgroundRedraw;
  font = createFont("Lucida Sans Unicode.ttf", 70, true);

  // Start Audio
  minim = new Minim(this);
  player = minim.loadFile( audioFile );
  if (!startWithPauzeButton && !isPlaying) {
    player.play();
    isPlaying = true;
  }

  // Start Analyzer
  analyzer = new AudioAnalyzer();
  beat = new BeatDetect(player.bufferSize(), player.sampleRate());
  beat.setSensitivity(300);

  // Setup Scenes
  // randomSeed(1);
  setupScenes();
}

void resetBackground(boolean reset) {
  if (reset) {
    background(0,0,0);
  }
  else {
    backgroundTimer = backgroundTimer - 1;
    if (backgroundTimer<=1) {
      noStroke();
      fill(0,0,0,1);
      rect(0,0,width,height);
      backgroundTimer = backgroundRedraw;
    }
  }
}


/*
  Global draw method
 */
public void draw() {
  if (startWithPauzeButton && !isPlaying) {
    drawPauseButton();
  }
  else {

    if (!isPlaying) {
      resetBackground(true);
      player.play();
      isPlaying = true;
    }

    // Reset background
    resetBackground(false);

    // Analyze audio
    analyzer.analyze();
    beat.detect(player.mix);

    // Draw the active scenes
    drawScenes();

    // Debugbar?
    if (debug) {
      drawDebugBar();
    }

    // End of audio? -> save fft analyzer & EXIT
    if ( player.position() >= player.length()) {
      if (analyzer.isNormalizing()) {
        analyzer.saveNormalizeData();
      }
      exit();
    }
  }
}
