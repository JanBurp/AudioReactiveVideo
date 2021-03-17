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
String audioFile = "No Worries.wav";


/*
  Declare you're scenes here.
  Best practice is to use a new .pde file for every scene with a name of 'scene####.pde'
  You can find some examples in CoreScenes.pde
 */
Scene scenes[] = {
  new waveLandscape(),
  // new waveCircles(),
  new coreOutro(),
  new coreFadeOut(),
};



/*
  Global setup method
 */
public void setup() {
  // Setup graphics
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

  // Setup Scenes
  // randomSeed(1);
  setupScenes();
}


/*
  Global draw method
 */
public void draw() {
  // Reset background
  // background(220,220,220);
  noStroke();
  fill(220,220,220,.5);
  rect(0,0,width,height);

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
