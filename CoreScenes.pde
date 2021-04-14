// ========================= Core Example Scenes ============


/*
  Example scene for showing an intro text and fading out
 */
class coreIntro extends Scene {
  coreIntro(SceneTime[] times) {
    super("coreIntro",times); // Active first 10 seconds
  }

  void draw() {
    textFont(font);
    textAlign(CENTER);
    float opacity = 100 - durationPercentage();
    fill(110,110,110, opacity);
    text( "Music: Zaagstof", width/2, height/2 - 100);
    text( "Visuals: Jan den Besten", width/2, height/2 + 100 );
  }
}

/*
  Example scene for showing a wave
 */
class coreWave extends Scene {

  int x,w,y,h;

  coreWave(SceneTime[] times) {
    super("coreWave",times); // Active all the time
  }

  void setup() {
    x = 0;
    w = width;
    y = 0;
    h = height;
  }

  void draw() {
    stroke(0,0,0);
    int yl = y + h/2;
    int yh = h/2;
    for(int i = 0; i < player.bufferSize() - 1; i++)
    {
      float x1 = map( i, 0, player.bufferSize(), x, w );
      float x2 = map( i+1, 0, player.bufferSize(), x, w );
      line( x1, yl + player.mix.get(i)*yh, x2, yl + player.mix.get(i+1)*yh );
    }
  }
}


/*
  Example scene for showing an outro text and fading in
 */
class coreOutro extends Scene {
  coreOutro(SceneTime[] times) {
    super("coreOutro",times);
  }

  void draw() {
    textFont(font);
    textAlign(CENTER);
    float opacity = durationPercentage() * 2;
    if (opacity>100) {
      opacity = 100 - opacity/2;
    }
    fill(128,128,128, opacity);
    text( "Music: Zaagstof", width/2, height/2 - 100);
    text( "Visuals: Jan den Besten", width/2, height/2 + 100 );
  }
}


/*
  Example scene for a simple fade out at the end
 */
class coreFadeOut extends Scene {
  coreFadeOut(SceneTime[] times) {
    super("coreFadeOut",times);
  }

  void draw() {
    float percentage = map2(durationPercentage(), 0,100,0,100, EXPONENTIAL, EASE_IN_OUT);
    fill(128,128,128,percentage);
    noStroke();
    rect(0,0,width, height);
  }
}
