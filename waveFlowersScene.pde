CircleWave ampCircles[];


class waveFlowers extends Scene {
  waveFlowers() {
    super("waveFlowers",15000,-20000);
  }

  void setup() {
    super.setup();
    ampCircles = new CircleWave[3];
    ampCircles[0] = new CircleWave(width/4,height/2,height/2,-1);
    ampCircles[1] = new CircleWave(width/2,height/2,height/2,0);
    ampCircles[2] = new CircleWave(width/4*3,height/2,height/2,1);
  }

  void draw() {
    ampCircles[0].draw();
    ampCircles[1].draw();
    ampCircles[2].draw();
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
