import org.json.*;

int [] positions; 
PFont f;
float transitionCount;
float thenTransition;
Event now;
Event then;
Event transition;
long durationStart;
long eventStart; //for testing, can be removed
int currEvent;
ArrayList events;

void setup() {
  size(400, 400);
  background(0);
  frameRate(30);
  setupPositions();
  setupFont();
  thenTransition = (positions[1] - positions[0])/255.0;
  events = loadEvents("event_list.json");  
  currEvent = currEventIndex(events);
  if (currEvent < 0) {
    println("Could not find the current event!");
    exit();
  }
  Event _now = (Event) events.get(currEvent);
  Event _then = (Event) events.get(currEvent + 1);
  eventStart=System.nanoTime(); //for testing, can be removed

  initialize(_now, _then);
}

void draw() {
  background(0);
  checkNewEvent();
  text("Now:", width/8, positions[0]);
  text("Then:", width/8, positions[1]);
  if (transitionCount > 0.0) {
    transition();
  }
  else {
    drawDurationCircles();
    text(now.name, 3*width/8, positions[0]);
    text(then.name, 3*width/8, positions[1]);
  }
}

void checkNewEvent() {
  long eventDuration = System.nanoTime() - eventStart;
  if (eventDuration >= now.duration) {
    currEvent++;
    if ( currEvent > events.size()) {
      println("No more events!");
      exit();
    }
    Event newEvent = (Event) events.get(currEvent);
    pushEvent(newEvent);
    eventStart = System.nanoTime();
  }
}

void initialize(Event _now, Event _then) {
  now = _now;
  then = _then;
  durationStart = _now.start * 1000000000L;
}

void pushEvent(Event _transition) {
  transition = _transition;
  durationStart = System.nanoTime();
  transitionCount = 255;
}

void drawDurationCircles() {
  float startX = width/8 + 10.0;
  float endX = rightmostText() - 10.0;
  float spaceBetween = (endX-startX)/7;
  if (spaceBetween < 20) {
    spaceBetween = 25;
  }
  float timeEllapsed = (float)(System.nanoTime() - durationStart);
  float percentEllapsed = timeEllapsed/now.duration;
  for (int i = 0; i < 8; i++) {
    if (percentEllapsed >i/8.0 && percentEllapsed <(i+1)/8.0)
    {
      fill(255 - 255*(8.0*(percentEllapsed - (i/8.0))));
    }
    else if (percentEllapsed > i/8.0) {
      fill(0);
    }
    ellipse(startX + spaceBetween*i, height/2, 20, 20);
    fill(255);
  }
}

void transition() {
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

void fadeText(float fade, int x, int y, String t) {
  fill(255, fade);
  text(t, x, y);
  fill(255);
}

void transitionText() {
  float yPosition = positions[1] - (thenTransition * (255-transitionCount));
  text(then.name, 3*width/8, yPosition);
}

void setupPositions() {
  positions = new int[2];
  positions[0] = 3*height/8;
  positions[1] = 5*height/8;
}

void setupFont() {
  f = createFont("Arial", 36, true);
  fill(255);
  textFont(f, 36);
  textAlign(LEFT, CENTER);
}

float rightmostText() {
  float nowTW = textWidth(now.name);
  float thenTW = textWidth(then.name);
  return max(nowTW, thenTW) + (3*width/8);
}

ArrayList loadEvents(String filename) {
  JSONArray eventList = new JSONArray();
  ArrayList events = new ArrayList();

  try {
    eventList = new JSONArray(join(loadStrings(filename), ""));
    for (int i = 0; i < eventList.length(); i++) {
      JSONObject e = eventList.getJSONObject(i);
      String name = e.getString("summary");
      int start =  e.getInt("start");
      int end = e.getInt("end");
      Event event = new Event(name, start, end);
      events.add(event);
    }
  } 
  catch(JSONException e) {
    e.getCause();
  }    

  return events;
}

int currEventIndex(ArrayList events) {
  long time = System.nanoTime() / 1000000000L;
  println(time);
   for(int i = 0; i < events.size(); i++) {
     Event e = (Event) events.get(i);
     if (time >= e.start && time < e.end) {
       return i;
     }
   } 
   return -1;
}

class Event {
  String name;
  int start;
  int end;
  long duration;

  public Event(String _name, int _start, int _end) {
    name = _name;
    start = _start;
    end = _end;
    duration = (long) pow(10, 9) * (end - start);
  }
}

