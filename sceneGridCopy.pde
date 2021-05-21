

class gridCopy extends Scene {

  gridCopy(SceneTime[] times) {
    super("gridCopy",times);
  }

  void setup() {
  }

  void draw() {
    if (beat.isSnare() || beat.isKick()) {
      int x1 = int(random(0,width));
      int y1 = int(random(0,height));
      int w = int(random(0,width/10));
      int h = int(random(0,height/10));
      int x2 = int(random(0,width));
      int y2 = int(random(0,height));
      copy(x1, y1, w, h, x2, y2, w*3, h*3);
    }
    if(beat.isHat()) {
      int x = int(random(0,width));
      int y = int(random(0,height));
      int w = int(random(0,width/10));
      int h = int(random(0,height/10));
      float level = player.mix.level();
      fill(255,255,255,20+100*level);
      rect(x,y,w,h);
    }
  }

}


