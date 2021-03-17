CircleWaveRound circles[];


class waveCircles extends Scene {
  waveCircles() {
    super("waveCircles",0,0);
  }

  void setup() {
    circles = new CircleWaveRound[3];
    int size = height/4;
    circles[0] = new CircleWaveRound(width/4,height/2,size,-1);
    circles[1] = new CircleWaveRound(width/2,height/2,size,0);
    circles[2] = new CircleWaveRound(width/4*3,height/2,size,1);
  }

  void draw() {
    if (beat.isKick()) {
      circles[0].move();
    }
    if (beat.isHat()) {
      circles[1].move();
    }
    if (beat.isSnare()) {
      circles[2].move();
    }

    circles[0].draw();
    circles[1].draw();
    circles[2].draw();
  }
}




class CircleWaveRound {

  int x, y, size, leftOrRight;
  int drawSize;

  CircleWaveRound(int x, int y,int size,int leftOrRight) {
    this.x = x;
    this.y = y;
    this.leftOrRight = leftOrRight;
    this.size = size;
    this.drawSize = size;
  }

  void move() {
    int max = drawSize/4;
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

    drawSize = size;
    if (player.position()<15000) {
      drawSize = drawSize * player.position() / 15000;
    }

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
      float radius = drawSize * (abs(volume)+.5);
      xc[i] = int(x + sin(angle) * radius);
      yc[i] = int(y + cos(angle) * radius);
    }


    if (leftOrRight<0) {
      stroke(110,55,55,10);
      fill(255,0,0,1);
    }
    if (leftOrRight==0) {
      stroke(110,110,55,10);
      fill(255,255,0,1);
    }
    if (leftOrRight>0) {
      stroke(55,55,110,10);
      fill(0,0,255,1);
    }
    beginShape();
    for(int i = 0; i < steps; i++) {
      vertex( xc[i],yc[i] );
    }
    endShape();

  }

}
