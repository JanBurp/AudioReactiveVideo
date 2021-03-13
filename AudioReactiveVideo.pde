/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "No Worries - kort.wav";

// Show debugbar and react to keypresses (LEFT|RIGHT)
boolean debug = true;

int nrOfScenes = 4;
Scene scenes[];

// Objects
CircleWave ampCircles[];
// LineWave lines[];
// int nrOflines = 100;
// int currentLine = 0;

PFont font;


/*
  SETUP
*/
public void setup() {
  size(1280,720,P2D);
  pixelDensity(2);
  colorMode(RGB, 255,255,255,100);
  background(220,220,220);
  font = createFont("Lucida Sans Unicode.ttf", 70, true);

  randomSeed(1);

  // Start Audio
  minim = new Minim(this);
  player = minim.loadFile( audioFile );
  player.play();

  // Analyzer
  analyzer = new AudioAnalyzer();
  beat = new BeatDetect(player.bufferSize(), player.sampleRate());
  beat.setSensitivity(300);

  // Scenes
  scenes = new Scene[nrOfScenes];
  scenes[0] = new Scene("coreIntro", 0, 10000);
  scenes[1] = new Scene("test", 5000, 20000);
  scenes[2] = new Scene("coreOutro", -20000, 20000);
  scenes[3] = new Scene("coreFadeOut", -5000, 5000);

  // Graphics
  ampCircles = new CircleWave[3];
  ampCircles[0] = new CircleWave(width/4,height/2,height/2,-1);
  ampCircles[1] = new CircleWave(width/2,height/2,height/2,0);
  ampCircles[2] = new CircleWave(width/4*3,height/2,height/2,1);

  // lines = new LineWave[nrOflines];
  // for(int i = 0; i < nrOflines; i++) {
  //   lines[i] = new LineWave();
  // }
}


public void draw() {
  // background(220,220,220);
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

  // Graphics
  ampCircles[0].draw();
  ampCircles[1].draw();
  ampCircles[2].draw();


  // Scenes
  for( int s=0; s<nrOfScenes; s++) {
    if (scenes[s].isActive()) {
      scenes[s].draw();
    }
  }

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




class CircleWave {

  int x, y, size, leftOrRight;

  CircleWave(int x, int y,int size,int leftOrRight) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.leftOrRight = leftOrRight;
  }

  void move() {
    int max = size/4;
    int xPlus = int(random(-max,max));
    x += xPlus;
    while (x>width) {
      x -= width;
    }
    while ( x<0 ) {
      x += width;
    }
    int yPlus = int(random(-max,max));
    y += yPlus;
    while (y>height) {
      y -= height;
    }
    while ( y<0 ) {
      y += height;
    }
  }

  void draw() {
    int steps = player.bufferSize() - 1;
    float angleStep = 2*PI / steps;
    int[] xc = new int[steps];
    int[] yc = new int[steps];

    for(int i = 0; i < steps; i++)
    {
      float volume = 0.0;
      if (leftOrRight<0) {
        volume = player.left.get(i);
      }
      if (leftOrRight==0) {
        volume = player.mix.get(i);
      }
      if (leftOrRight>0) {
        volume = player.right.get(i);
      }
      float angle = angleStep * i;
      float radius = size * abs(volume*2);
      xc[i] = int(x + sin(angle) * radius);
      yc[i] = int(y + cos(angle) * radius);
    }


    if (leftOrRight<0) {
      stroke(110,55,55,20);
      fill(220,0,0,7);
    }
    if (leftOrRight==0) {
      stroke(110,110,55,20);
      fill(220,220,0,7);
    }
    if (leftOrRight>0) {
      stroke(55,55,110,20);
      fill(0,0,220,7);
    }
    beginShape();
    for(int i = 0; i < steps; i++) {
      vertex( xc[i],yc[i] );
    }
    endShape();

  }

}


// class LineWave {

//   int steps;
//   float[] points;
//   int y = height/2;
//   int yDiff = 50;
//   int ySpeed = 5;

//   LineWave() {
//     steps = player.bufferSize() - 1;
//     points = new float[steps];
//     calcPoints();
//   }

//   void calcPoints() {
//     for(int i = 0; i < steps; i++)
//     {
//       points[i] = player.mix.get(i);
//     }
//   }

//   void draw() {
//     stroke(0,0,0);
//     for(int i = 1; i < steps; i++)
//     {
//       float x1 = map( i, 0, steps, 0, width );
//       float x2 = map( i+1, 0, steps, 0, width );
//       line( x1, y - points[i-1]*yDiff, x2, y - points[i]*yDiff );
//     }
//     y += ySpeed;
//     if (y > height) {
//       y = height/2;
//       calcPoints();
//     }
//   }
// }


