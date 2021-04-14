

class waveLandscapeTrigger extends Scene {

  Wave waves[];

  waveLandscapeTrigger(SceneTime[] times) {
    super("waveLandscapeTrigger",times);
  }

  void setup() {
    waves = new Wave[6];
    int size = width;
    int w=0;
    waves[w++] = new Wave( size, color(255,0,0) );
    waves[w++] = new Wave( size, color(255,255,0) );
    waves[w++] = new Wave( size, color(255,0,255) );
    waves[w++] = new Wave( size, color(0,255,255) );
    waves[w++] = new Wave( size, color(0,255,0) );
    waves[w++] = new Wave( size, color(255,255,255) );
  }

  void draw() {
    for( int w=0; w<waves.length; w++) {
      waves[w].moveAndDraw();
    }
  }


  class Wave {

    MovingPoint point[] = new MovingPoint[2];
    int range;
    color c;

    Wave(int size, color c) {
      float maxSpeed = 1;
      point[0] = new MovingPoint( int(random(0,width)), int(random(0,height)), maxSpeed);
      point[1] = new MovingPoint( int(random(point[0].x()-size,point[0].x()+size)), int(random(point[0].y()-size,point[0].y()+size)), maxSpeed);
      this.c = c;
      this.range = size/5;
    }

    void moveAndDraw() {
      this.move();
      this.draw();
    }


    void move() {
      if (player.mix.level() > .2) {
        point[0].move(true);
        point[1].move(true);
        // slice();
      }
      else {
        point[0].move(false);
        point[1].move(false);
      }
    }

    void slice() {
      int w = int(random(width/2));
      int h = int(random(height/2));
      int x1 = int(random(0, width));
      int y1 = int(random(0, height));
      int x2 = int(random(0, width));
      int y2 = int(random(0, height));
      copy(x1, y1, w, h, x2, y2, w, h);
    }

    void draw() {
      float level = player.mix.level();
      float red = red(c);
      float green = green(c);
      float blue = blue(c);
      float alpha = 2 + 100*level;
      if (timePlayed()<1000) {
        alpha = alpha * timePlayed()/1000;
      }
      color currentColor = color(red,green,blue,alpha);
      stroke(currentColor);
      strokeWeight(1 + 2*level);

      int size = player.bufferSize();
      for(int i = 0; i < size - 1; i++)
      {
        float angle = PVector.angleBetween(point[0].getVector(), point[1].getVector());
        float volume = player.mix.get(i)*range;
        float x1 = map( i, 0,size, point[0].x(),point[1].x() ) + volume * cos(angle);
        float y1 = map( i, 0,size, point[0].y(),point[1].y() ) + volume * sin(angle);

        volume = player.mix.get(i+1)*range;
        float x2 = map( i+1, 0,size, point[0].x(),point[1].x() ) + volume * cos(angle);
        float y2 = map( i+1, 0,size, point[0].y(),point[1].y() ) + volume * sin(angle);

        line( x1, y1, x2, y2);
      }

    }

  }


  class MovingPoint {

    PVector position,speed;

    MovingPoint(int x, int y, float maxSpeed) {
      position = new PVector( x, y );
      speed = new PVector( random(1,maxSpeed), random(1,maxSpeed) );
    }

    void move(boolean fast) {
      if (fast) {
        PVector fastSpeed = PVector.mult(speed,40);
        position.add(fastSpeed);
      }
      else {
        position.add(speed);
      }

      if (position.x > width*1.25 || position.x < 0-width*0.25 ) {
        speed.x = - speed.x;
      }
      if (position.y > height*1.25 || position.y < 0-height*0.25 ) {
        speed.y = - speed.y;
      }
    }

    PVector getVector() {
      return position;
    }

    int x() {
      return int(position.x);
    }

    int y() {
      return int(position.y);
    }

  }



}





