// Put you're audio file in the 'data' folder and fill in the name:
String audioFile = "No Worries - kort.wav";

// Declare you're scenes
Scene scenes[] = {
  new coreIntro(),
  new waveFlowers(), // see waveFlowersScene.pde
  new coreOutro(),
  new coreFadeOut(),
};


//  Some core scenes

// =========================

class coreIntro extends Scene {
  coreIntro() {
    super("coreIntro",0,10000);
  }

  void setup() {
    super.setup();
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

// =========================

class coreOutro extends Scene {
  coreOutro() {
    super("coreOutro",-20000,20000);
  }

  void setup() {
    super.setup();
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

// =========================

class coreFadeOut extends Scene {
  coreFadeOut() {
    super("coreFadeOut",-10000,10000);
  }

  void setup() {
    super.setup();
  }

  void draw() {
    float percentage = durationPercentage();
    fill(100,100,100,percentage);
    noStroke();
    rect(0,0,width, height);
  }
}
