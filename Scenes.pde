/*
  A tool to create visuals reacting on an audiofile
  (c) Jan den Besten
 */

class Scene {

  String name;
  int startTime;
  int duration;

  Scene(String name, int startTime, int duration) {
    this.name = name;
    this.startTime = startTime;
    this.duration = duration;
  }

  boolean isActive() {
    if (startTime>=0 && timePlayed()>=startTime && timePlayed()<startTime+duration) {
      return true;
    }
    if (startTime<0 && timeLeft()<=abs(startTime) && durationMillis()<duration ) {
      return true;
    }
    return false;
  }

  int durationMillis() {
    if (startTime>=0) {
      return timePlayed() - startTime;
    }
    else {
      return abs(startTime) - timeLeft();
    }
  }

  float durationPercentage() {
    return (float)durationMillis()*100 / (float)duration;
  }

  void draw() {
    method(name);
  }

}

Scene findSceneByName(String name) {
  int s = 0;
  while (scenes[s].name!=name && s<nrOfScenes) {
    s++;
  }
  if (scenes[s].name==name) {
    return scenes[s];
  }
  return new Scene("false",0,0);
}
