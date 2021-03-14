/*

  A tool to create visuals reacting on an audiofile (c) Jan den Besten.

  Define your're scenes in Scenes.pde

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
  randomSeed(1);
  setupScenes();
}


public void draw() {
  // Reset background
  noStroke();
  fill(220,220,220,1);
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
