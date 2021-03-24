/*

  A tool to create visuals reacting on an audiofile (c) Jan den Besten.

 */

// Global settings
boolean debug = false;
boolean doAnalyze = false;
float smoothingFactorUp = 0.8;
float smoothingFactorDown = 0.1;

// Lucida Font
PFont font;

// Audio libraries and globals
import ddf.minim.analysis.*;
import ddf.minim.*;
Minim minim;
AudioPlayer player;
FFT         fft;
BeatDetect  beat;
AudioAnalyzer analyzer;
boolean isPlaying = false;


/*
  Shows a debugbar:
  - Name and time
  - Active scenes
  - Waveform
 */
void drawDebugBar() {
  int barHeight = 50;
  noStroke();
  fill(0,0,0,50);
  rect(0,0,width,barHeight);
  fill(0,255,0);
  textSize(12);
  text( audioFile + " - " + timeFormat(timePlayed()) + " / " + timeFormat(player.length()), 10, barHeight/2 );

  // Scenes
  String activeScenes = "Scenes: ";
  for( int s=0; s<scenes.length; s++) {
    if (scenes[s].isActive()) {
      activeScenes += scenes[s].name +"["+percentageFormat(scenes[s].durationPercentage())+"]" + ", ";
    }
  }
  text( activeScenes, width/3, barHeight/2 );

  if (analyzer.isNormalizing()) {
    text( "ANALYZING", width*2/3, barHeight/2 );
  }

  // draw a line to show where in the song playback is currently located
  float posx = map(player.position(), 0, player.length(), 0, width);
  strokeWeight(1);
  stroke(255,0,0);
  line(posx, 0, posx, barHeight-1);
  stroke(255,255,255);

  analyzer.drawWaveformsRect(0,0,width,barHeight);
}

void drawPauseButton() {
  textFont(font);
  textAlign(CENTER);
  fill(110,110,110);
  text( "press SPACEBAR to start", width/2, height/2 );
}

/*
  When in debugmode, reacts on left and right cursor keys for skipping through audio
 */
void keyPressed()
{
  if (debug) {
    if (key==CODED) {
      if (keyCode == LEFT) {
        player.skip(-10000);
      } else if (keyCode == RIGHT) {
        player.skip(10000);
      }
    }
    else {
      if ( player.position() >= player.length() )
      {
        player.pause();
      }
      else {
        if ( player.isPlaying() )
        {
          player.pause();
        }
        else
        {
          player.play();
        }
      }
    }
  }
  if (startWithPauzeButton && !isPlaying) {
    if (key==' ') {
      startWithPauzeButton = false;
      resetBackground(true);
      player.play();
      isPlaying = true;
    }
  }
}


/*
  Returns time passed in milliseconds
 */
int timePlayed() {
  return player.position();
}

/*
  Returns time left in milliseconds
 */
int timeLeft() {
  return player.length() - player.position();
}

/*
  Format milliseconds in a nice string format
 */
String timeFormat(int millis) {
  int seconds = millis / 1000;
  int minutes = seconds / 60;
  seconds -= minutes*60;
  millis -= (minutes*60) + (seconds*1000);
  return minutes +":"+ intFormat(seconds,2,"0");// +"."+ intFormat(millis,4,"0");
}

/*
  Format a number with a fixed length and prefixed characters (001 instead of 1 for example)
 */
String intFormat(int value, int length, String ch) {
  String format = "";
  if (length>3 && value<1000) {
    format += ch;
  }
  if (length>2 && value<100) {
    format += ch;
  }
  if (length>1 && value<10) {
    format += ch;
  }
  return format + value;
}

/*
  Format a float (0-100) in a percentage string (45%)
 */
String percentageFormat(float value) {
  return intFormat(int(value),2,"0") + "%";
}


//  ================== SCENES ======================



/*
  Iterates to all scenes and call setup methods
 */
void setupScenes() {
  println();
  println("==== Initializing. Audio file: `",audioFile,"` length: ",player.length());
  println();

  for( int s=0; s<scenes.length; s++) {
    scenes[s].initialize();
    scenes[s].setup();
  }
}

/*
  Iterates to all scenes, check if a scene is active and call draw method
 */
void drawScenes() {
  for( int s=0; s<scenes.length; s++) {
    if (scenes[s].isActive()) {
      scenes[s].draw();
    }
  }
}

/*
  Scene Class

  User scenes inherit from this class.

 */
class Scene {

  // A user defined name, for debugging options
  public String name;

  // Time in milliseconds from start of the audio when the scene starts. A value of 0 is start of audio. Can be negative, in that case the starttime is calculated from the end of the auidio.
  public int startTime;

  // Duration time in milliseconds of the scene. A value of 0 is calculated and set to a druation from startTime to of audio. StartTime + duration cannot exceed lenght of audio.
  public int duration;

  /*
    Constructor
   */
  Scene(String name, int startTime, int duration) {
    this.name       = name;
    this.startTime  = startTime;
    this.duration   = duration;
  }

  /*
    Initialize method is called once at the start of the script.
    Calculate startTime and duration (if set zero of negative)
   */
  private void initialize() {
    if (startTime<0) {
      startTime = player.length() - abs(startTime);
    }
    if (duration<=0) {
      duration = player.length() - abs(duration) - startTime;
    }
    println( this.name," - ", this.startTime, ":", this.duration );
  }

  /*
    Setup method is called once at the start of the script. Initilize your're scene here.
   */
  public void setup() {
  }

  /*
    Draw method is called every draw iteration of the sketch. Draw you're scene here.
   */
  public void draw() {
  }

  /*
    Test if scene is active (needs to be drawn)
   */
  public boolean isActive() {
    if (timePlayed()>=startTime && timePlayed()<startTime+duration) {
      return true;
    }
    return false;
  }

  /*
    Returns the duration of the scene (from the start of the scene) in milliseconds.
   */
  public int durationMillis() {
    return timePlayed() - startTime;
  }

  /*
    Return the duration of the scene as a percentage of the length of the scene. From 0.0 to 100.0.
   */
  public float durationPercentage() {
    return (float)durationMillis()*100 / (float)duration;
  }

}





/*

  Audio Analyzer Class

  Handles analizing, normalizing and smoothing different audio spectrums.
  With tools to show waveform and equalizer.
  Writes normalize data to a file after first run. And uses this data to normalize the audio spectrums for more usefull equalizer visualisations.

 */

class AudioAnalyzer {

  int bands = 0;
  float volume = 0.0;
  float smoothVolume = 0.0;
  float[] volumeSpectrum;
  float[] smoothSpectrum;
  float[] maxSpectrum;
  float[] rmsSpectrum;
  float[] normalizedFactor;
  float[] maxedFactor;
  long rmsSamples = 0;
  boolean isNormalizing = false;

  AudioAnalyzer() {
    fft = new FFT( player.bufferSize(), player.sampleRate() );
    fft.logAverages( 33, 1 );
    bands = fft.avgSize();

    volumeSpectrum = new float[bands];
    smoothSpectrum = new float[bands];
    maxSpectrum = new float[bands];
    rmsSpectrum = new float[bands];
    maxedFactor = new float[bands];
    normalizedFactor = new float[bands];

    for(int i = 0; i < bands; i++){
     smoothSpectrum[i] = 0.0;
     maxSpectrum[i] = 0.0;
     rmsSpectrum[i] = 0.0;
     maxedFactor[i] = 1.0;
     normalizedFactor[i] = 1.0;
    }

    loadNormalizeData();
  }

  void analyze() {
    volume = player.mix.level();
    // Smoothing
    if (volume>smoothVolume) {
      smoothVolume += (volume - smoothVolume) * smoothingFactorUp;
    }
    else {
      smoothVolume += (volume - smoothVolume) * smoothingFactorDown;
    }

    // FFT
    fft.forward( player.mix );
    for(int i = 0; i < bands; i++){
      volumeSpectrum[i] = fft.getAvg(i);

      // analyze
      if (isNormalizing) {
        if (volumeSpectrum[i] > maxSpectrum[i]) { maxSpectrum[i]=volumeSpectrum[i]; }
        rmsSpectrum[i] += volumeSpectrum[i] * volumeSpectrum[i];
        rmsSamples++;
      }
      else {
        // Factor
        if (volumeSpectrum[i]>=(rmsSpectrum[i]/2) ) {
          volumeSpectrum[i] = volumeSpectrum[i] * maxedFactor[i];
        }
        else {
          volumeSpectrum[i] = volumeSpectrum[i] * normalizedFactor[i];
        }
      }

      // Smoothing
      if (volumeSpectrum[i]>smoothSpectrum[i]) {
        smoothSpectrum[i] += (volumeSpectrum[i] - smoothSpectrum[i]) * smoothingFactorUp;
      }
      else {
        smoothSpectrum[i] += (volumeSpectrum[i] - smoothSpectrum[i]) * smoothingFactorDown;
      }

    }
  }

  boolean isNormalizing() {
    return isNormalizing;
  }

  float getVolume() {
    return volume;
  }

  float getVolumeSmooth() {
    return smoothVolume;
  }

  float getSpectrumBand(int band) {
    return volumeSpectrum[band];
  }

  float getSpectrumBandSmooth(int band) {
    return smoothSpectrum[band];
  }

  void loadNormalizeData() {
    if (doAnalyze) {
      File file = dataFile(getNormalizeFilename());
      isNormalizing = !file.isFile();
      if (isNormalizing){
        Table table;
        table = loadTable("data/"+getNormalizeFilename(), "header");
        if ( table.getRowCount() > 0 ) {
          println(table.getRowCount() + " total rows in table");

          for (TableRow row : table.rows()) {
            int band = row.getInt("band");
            float max = row.getFloat("max");
            float rms = row.getFloat("rms");
            rmsSpectrum[band] = rms;
            maxedFactor[band] = 1/max;
            normalizedFactor[band] = 1/rms;
            // println("Band ",band," => ",max,rmsSpectrum[band],normalizedFactor[band],maxedFactor[band]);
          }
        }
      }
      else {
        println("No normalize data => Analyzing now...");
      }
    }
  }

  void saveNormalizeData() {
    float rmsFactor = 0.0;
    Table table = new Table();
    table.addColumn("band");
    table.addColumn("max");
    table.addColumn("rms");

    for(int i = 0; i < bands; i++) {
      rmsFactor = sqrt(rmsSpectrum[i]/rmsSamples);
      TableRow newRow = table.addRow();
      newRow.setInt("band", i);
      newRow.setFloat("max", maxSpectrum[i]);
      newRow.setFloat("rms", rmsFactor);
    }
    saveTable(table, "data/"+getNormalizeFilename());
    println("Saved analyse");
  }

  String getNormalizeFilename() {
    return "fft_analyze_"+bands+".csv";
  }


  void drawEqualizer(int x, int y, int w, int h) {
      stroke(255,0,0);

      int bandwidth = width/bands;
      for(int i = 0; i < bands; i++)
      {
        noFill();
        stroke(0,0,0);
        strokeWeight(1);
        rect( i*bandwidth, 0, bandwidth, height);

        fill(255,0,0);
        rect( i*bandwidth, height, bandwidth, -height * smoothSpectrum[i] );
      }
    }

    void drawWaveformsRect(int x, int y, int w, int h) {
      int y1 = y + h/4;
      int y2 = y + h*3/4;
      int yh = h/2;
      for(int i = 0; i < player.bufferSize() - 1; i++)
      {
        float x1 = map( i, 0, player.bufferSize(), x, w );
        float x2 = map( i+1, 0, player.bufferSize(), x, w );
        line( x1, y1 + player.left.get(i)*yh, x2, y1 + player.left.get(i+1)*yh );
        line( x1, y2 + player.right.get(i)*yh, x2, y2 + player.right.get(i+1)*yh );
      }
    }

}
