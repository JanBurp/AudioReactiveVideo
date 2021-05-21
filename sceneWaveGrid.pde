

class waveGrid extends Scene {

  Wave waves[];

  waveGrid(SceneTime[] times) {
    super("waveGrid",times);
  }

  void setup() {
    waves = new Wave[4];
    int speed = 10;
    waves[0] = new Wave( "ver", speed*5, width/4*3, color(255,0,255) );
    waves[1] = new Wave( "ver", speed, width/4, color(0,0,255) );
    waves[2] = new Wave( "hor", speed*5, height/4*3, color(255,0,0) );
    waves[3] = new Wave( "hor", speed, height/4, color(255,255,0) );
  }

  void draw() {
    for( int w=0; w<waves.length; w++) {
      waves[w].moveAndDraw();
    }
  }


  class Wave {

    MovingPoint point[] = new MovingPoint[2];
    int range;
    int speed;
    color c;
    String type;

    Wave( String type, int speed, int pos, color c) {
      if (type=="ver") {
        point[0] = new MovingPoint( pos, 0, speed,0);
        point[1] = new MovingPoint( pos, height, speed,0);
      }
      else {
        point[0] = new MovingPoint( 0, pos, 0,speed);
        point[1] = new MovingPoint( width, pos, 0,speed);
      }
      this.type = type;
      this.c = c;
      this.speed = abs(speed);
      this.range = height/2;
    }

    void moveAndDraw() {
      this.move();
      this.draw();
    }


    void move() {
      point[0].move();
      if (type=="ver") {
        point[1].position.x = point[0].position.x;
        point[1].position.y = height;
      }
      else {
        point[1].position.x = width;
        point[1].position.y = point[0].position.y;
      }
    }

    void draw() {
      float level = player.mix.level();
      float red = red(c);
      float green = green(c);
      float blue = blue(c);
      float alpha = 5 + (95-speed) * level;
      color currentColor = color(red,green,blue,alpha);
      stroke(currentColor);
      strokeWeight(1 + 15*level);

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

    MovingPoint(int x, int y, float speedX, float speedY) {
      position = new PVector( x, y );
      speed = new PVector( speedX, speedY );
    }

    void move() {
      if (speed.x>0) {
        position.x = random(0,width/speed.x) * speed.x;
      }
      if (speed.y>0) {
        position.y = random(0,height/speed.y) * speed.y;
      }
      // position.add(speed);
      // if (position.x > width || position.x < 0 ) {
      //   speed.x = - speed.x;
      // }
      // if (position.y > height || position.y < 0 ) {
      //   speed.y = - speed.y;
      // }
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


