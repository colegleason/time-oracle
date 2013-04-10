int [] positions; 
PFont f;
float transitionCount;
float thenTransition;
Event now;
Event then;
Event transition;
long durationStart;
long testStart; //for testing, can be removed

void setup() {
  size(400, 400);
  background(0);
  frameRate(30);
  setupPositions();
  setupFont();
  thenTransition = (positions[1] - positions[0])/255.0;
  //testing! 
  //must set a now and then to begin, as well as start the duration
  Event _now = new Event("First Event", 30000000000L); //duration: 1 minute
  Event _then = new Event("Second Event", 30000000000L);
  testStart=System.nanoTime(); //for testing, can be removed
  
  initialize(_now, _then);
}

void draw() {
  background(0);
  testFunction();
  text("Now:", width/8, positions[0]);
  text("Then:", width/8, positions[1]);
  if(transitionCount > 0.0){
    transition();
  }
  else {
    drawDurationCircles();
    text(now.name, 3*width/8, positions[0]);
    text(then.name, 3*width/8, positions[1]);
  }
}

void testFunction(){
  long testDuration = System.nanoTime() - testStart;
  if (testDuration >= now.duration){
    Event newEvent = new Event("Next Event", 60000000000L);
    pushEvent(newEvent);
    testStart = System.nanoTime();
  }
}

void initialize(Event _now, Event _then) {
  now = _now;
  then = _then;
  durationStart = System.nanoTime();
}

void pushEvent(Event _transition){
  transition = _transition;
  durationStart = System.nanoTime();
  transitionCount = 255;
}

void drawDurationCircles(){
  float startX = width/8 + 10.0;
  float endX = rightmostText() - 10.0;
  float spaceBetween = (endX-startX)/7;
  if (spaceBetween < 20) {
    spaceBetween = 25;
  }
  float timeEllapsed = (float)(System.nanoTime() - durationStart);
  float percentEllapsed = timeEllapsed/now.duration;
  for(int i = 0; i < 8; i++){
    if (percentEllapsed >i/8.0 && percentEllapsed <(i+1)/8.0)
    {
      fill(255 - 255*(8.0*(percentEllapsed - (i/8.0))));
    }
    else if (percentEllapsed > i/8.0){
      fill(0);
    }
    ellipse(startX + spaceBetween*i, height/2, 20, 20);
    fill(255);
  }
}

void transition(){
  fadeText(transitionCount, 3*width/8, positions[0], now.name);
  transitionText();
  fadeText(255-transitionCount, 3*width/8, positions[1], transition.name);
  transitionCount = transitionCount - 1;
  if (transitionCount == 0.0) {
    now = then;
    then = transition;
    durationStart = System.nanoTime();
  }
}

void fadeText(float fade, int x, int y, String t){
  fill(255,fade);
  text(t, x, y);
  fill(255);
}

void transitionText(){
  float yPosition = positions[1] - (thenTransition * (255-transitionCount));
  text(then.name, 3*width/8, yPosition);
}

void setupPositions(){
  positions = new int[2];
  positions[0] = 3*height/8;
  positions[1] = 5*height/8;
}

void setupFont(){
  f = createFont("Arial", 36, true);
  fill(255);
  textFont(f, 36);
  textAlign(LEFT, CENTER);
}

float rightmostText(){
  float nowTW = textWidth(now.name);
  float thenTW = textWidth(then.name);
  return max(nowTW, thenTW) + (3*width/8);
}

class Event {
  String name;
  long duration;
  
  public Event(String _name, long _duration){
    name = _name;
    duration = _duration;
  }
  
}
