/*

  Put you're audio file (.wav) in the 'data' folder and fill in the name:

 */

String audioFile = "No Worries - kort.wav";


/*

  Declare you're scenes here.
  Best practice is to use a new .pde file for every scene.
  Some standard scenes are it this file.

 */

Scene scenes[] = {
  new coreIntro(),
  new coreWave(),
  new waveFlowers(), // see waveFlowersScene.pde
  new coreOutro(),
  new coreFadeOut(),
};


// ========================= Core Example Scenes ============


/*
  Example scene for showing an intro text and fading out
 */
class coreIntro extends Scene {
  coreIntro() {
    super("coreIntro",0,10000); // Active first 10 seconds
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

  coreWave() {
    super("coreWave",0,0); // Active all the time
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
  coreOutro() {
    super("coreOutro",-20000,0); // Active last 20 seconds
  }

  void draw() {
    textFont(font);
    textAlign(CENTER);
    float opacity = durationPercentage();
    fill(110,110,110, opacity);
    text( "Music: Zaagstof", width/2, height/2 - 100);
    text( "Visuals: Jan den Besten", width/2, height/2 + 100 );
  }
}


/*
  Example scene for a simple fade out at the end
 */
class coreFadeOut extends Scene {
  coreFadeOut() {
    super("coreFadeOut",-10000,0); // Active last 10 seconds
  }

  void draw() {
    float percentage = durationPercentage();
    fill(100,100,100,percentage);
    noStroke();
    rect(0,0,width, height);
  }
}
