import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import oscP5.*; 
import netP5.*; 
import java.net.*; 
import java.util.Enumeration; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class newLaserGame extends PApplet {

// Server stuff





OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
NetAddress myBroadcastLocation;
int listenPort = 32000;
int broadcastPort = 12000;

final static String connectPattern = "/server/connect";
final static String disconnectPattern = "/server/disconnect";
final static String ADDR_INIT = "/initialize/begin";
final static String ADDR_INITDONE = "/initialize/end";
final static String ADDR_NEWRAY = "/new/ray";
final static String ADDR_NEWMIRROR = "/new/mirror";
final static String ADDR_NEWENEMY = "/new/enemy";
final static String ADDR_MIRRORANGLE = "/mirror/angle/";
final static String ADDR_MIRRORORIGIN = "/mirror/origin/";
final static String ADDR_RAYANGLE = "/ray/angle/";
final static String ADDR_RAYX = "/ray/x/";
final static String ADDR_RAYY = "/ray/y/";
final static int MIRROR_SIZE = 100;
final static int ENEMY_SIZE = 20;
boolean isInitializing = false;

final static int CONN_UNCONNECTED = 0;
final static int CONN_SERVER = 1;
final static int CONN_CLIENT = 2;
int connectionType = CONN_UNCONNECTED;
int clientIndex = 0;


Ray laser;
static final int HOVER_DISTANCE = 1;
ArrayList<Ray> rays;
ArrayList<Mirror> mirrors;
ArrayList<Enemy> enemies;
PVector mousePosition;
PVector mousePressedPos;
PVector mouseReleasedPos;
boolean followMouse = true;
int enemiesHit, numBounces = 0;
static final int screenW = 500;
static final int screenH = 500;
static final int rayDist = (int)sqrt((float)(Math.pow(screenW, 2) + Math.pow(screenH, 2)));
int screenOffsetX = clientIndex * screenW;

public String getBroadcastAddress() {
  System.setProperty("java.net.preferIP4Stack", "true");

  // Try getting broadcast address for en0 first, if not, get the next available adapter's broadcast address

  try {
    Enumeration<NetworkInterface> interfaces =
      NetworkInterface.getNetworkInterfaces();

    while (interfaces.hasMoreElements ()) {
      NetworkInterface networkInterface = interfaces.nextElement();
      println(networkInterface.getDisplayName());
      // Commented out for local debugging
      //      if (networkInterface.isLoopback() || !networkInterface.getDisplayName().equals("en0"))
      if (networkInterface.isLoopback())
        continue;    // Don't want to broadcast to the loopback interface
      for (InterfaceAddress interfaceAddress :
               networkInterface.getInterfaceAddresses()) {
          InetAddress broadcast = interfaceAddress.getBroadcast();
        if (broadcast == null)
          continue;
        // Use the address, but get rid of the leading slash
        String address = broadcast.toString().substring(1, broadcast.toString().length());
        return address;
      }
    }
  } 
  catch (Exception e) {
    println(e);
  }
  return "";
}

public void setup() {
  // Start all instances to Client by default
  //  oscP5 = new OscP5(this, listenPort); // Server setup
  // Commented out for debugging
//  myBroadcastLocation = new NetAddress(getBroadcastAddress(), listenPort);
  myBroadcastLocation = new NetAddress("127.0.0.1", listenPort);
  oscP5 = new OscP5(this, broadcastPort);
  println("Broadcast address: " + getBroadcastAddress());

  size( screenW, screenH );
  ellipseMode(RADIUS);
  mousePressedPos = new PVector(0, 0);
  mousePosition = new PVector(mouseX, mouseY);
  mirrors = new ArrayList<Mirror>();
  rays = new ArrayList<Ray>();
  enemies = new ArrayList<Enemy>();
  fill(0);
  smooth();
  laser = new Ray(200.0f, 200.0f, 0);
  mirrors.add(new Mirror(1000, 300, 45, MIRROR_SIZE));
}



public void update() {
  // Get the initial size of Ray array
  int numRays = 1;
  rays.clear();
  rays.add(laser);
  numBounces = 0;

  // Clear all previous hit states
  enemiesHit = 0;
  for (Enemy enemy : enemies) {
    enemy.hit = false;
  }

  // Loop through Ray array
  for (int j=0; j<numRays; j++) {
    Ray ray = rays.get(j);

    // Loop through Mirrors array. Find CLOSEST intersection first, then calculate bounce
    Mirror closestMirror = null;
    PVector closestIntersection = null;
    for (int i=0; i<mirrors.size(); i++) {
      //        mirrors.get(i).draw();
      PVector intersection = rayIntersection(ray, mirrors.get(i));
      if (intersection != null && intersection != ray.origin ) {
        if ( closestIntersection == null || distOfPVectors(ray.origin, intersection) < distOfPVectors(ray.origin, closestIntersection)) {
          closestIntersection = intersection;
          closestMirror = mirrors.get(i);
        }
      }
    }

    if (closestIntersection != null && closestMirror != null) {
      ellipse( closestIntersection.x, closestIntersection.y, 5, 5);
      float bounceAngle = reflectionAngleInDegrees( ray, closestMirror, closestIntersection );
      Ray reflection = new Ray( closestIntersection.x + cos(radians(bounceAngle)) * 2, closestIntersection.y + sin(radians(bounceAngle)) * 2, bounceAngle);
      rays.add(reflection);
      numRays++;
      numBounces++;
      ray.distance = dist(ray.origin.x, ray.origin.y, closestIntersection.x, closestIntersection.y)+5;
    } 
    else if ( ray.distance < rayDist ) {
      ray.distance = rayDist;
      println("Resetting distance");
    }

    // Check for enemy collisions
    for (Enemy enemy : enemies) {
      if (enemy.checkCollision(ray) && !enemy.hit) {
        enemy.hit = true; 
        enemiesHit++;
      }
    }
  }
}

public void draw() {
  background(255);
  mousePosition.x = mouseX + screenOffsetX;
  mousePosition.y = mouseY;
  
  if (!isInitializing) {
    update();
    
    // If this is a client, shift everything to the right by clientIndex
    pushMatrix();
    if (connectionType == CONN_CLIENT)
      translate(-screenOffsetX, 0);
    
    // Draw rays
    pushStyle();
    stroke(255, 0, 0);
    for (Ray ray : rays) {
      ray.draw();
    }
    popStyle();
  
    // Draw mirrors
    for (Mirror mirror : mirrors) {
      // Test for hovering
      mirror.hover = mirror.isHovering(mousePosition);
      mirror.draw();
    }
  
    // Draw enemies
    for (Enemy enemy : enemies) {
      enemy.draw();
    }
    
    popMatrix();
  
    // Draw stats
    pushStyle();
    fill(0);
    stroke(0);
    textSize(25);
    textAlign(LEFT);
    String connectionStatus = "";
    switch (connectionType) {
    case CONN_SERVER:
      connectionStatus = "SERVER";
      break;
  
    case CONN_CLIENT:
      connectionStatus = "CLIENT";
      break;
  
    default:
      connectionStatus = "SINGLE PLAYER";
      break;
    }
  
    if (connectionType == CONN_CLIENT) {
      connectionStatus += " (" + myBroadcastLocation.address() + ")";
    }
    text("Enemies hit: " + enemiesHit + "/" + enemies.size() + " Bounces: " + numBounces + " " + connectionStatus, 10, 35);
    pushStyle();
    textSize(18);
    textAlign(CENTER);
    text("Press E to spawn new Enemy. Press M to spawn new Mirror. Press SPACEBAR to lock Laser.\nClick and drag mirrors to move. MouseWheel to rotate mirrors.", width/2, height - 35);
    popStyle(); 
    popStyle();
  
    // Draw connected clients
    for (int i = 0; i < myNetAddressList.size(); i++) {
      text(myNetAddressList.get(i).address(), 10, (10*i)+10);
    }
  }
}


public float reflectionAngleInDegrees( Ray incoming, Ray surface, PVector intersection ) {

  float laserX = incoming.origin.x-intersection.x;
  float laserY = (incoming.origin.y-intersection.y)*-1;

  float incidentAngle = degrees(atan(laserY/laserX));


  if (laserX < 0) {
    incidentAngle += 180;
  }

  if (laserX - intersection.x >= 0 && laserY < 0) {
    incidentAngle += 360;
  }

  float bounceAngle = 180 - incidentAngle - 2 * surface.angle;
  if (bounceAngle < 0) {
    bounceAngle += 360;
  }

  //  pushStyle();
  //  fill(0);
  //  stroke(0);
  //  text("Incident angle: " + incidentAngle + " Bounce angle: " + bounceAngle, width/2, height - 20); 
  //  popStyle();
  return -bounceAngle;
}

public void keyPressed() {
  OscMessage m;
  switch (key) {
    case('e'):
      if (connectionType == CONN_SERVER) {
        Enemy newEnemy = new Enemy( mousePosition.x, mousePosition.y, 20, ENEMY_SIZE);
        enemies.add(newEnemy);
      }
      m = new OscMessage(ADDR_NEWENEMY);
      m.add(mousePosition.x);
      m.add(mousePosition.y);
      m.add(45);
      sendMessage(m);
      break;
    case('m'):
      if (connectionType == CONN_SERVER) {
        Mirror mirror = new Mirror(mousePosition.x, mousePosition.y, 45, MIRROR_SIZE);
        mirrors.add(mirror);
      }
      m = new OscMessage(ADDR_NEWMIRROR);
      m.add(mousePosition.x);
      m.add(mousePosition.y);
      m.add(45.0f);
      sendMessage(m);
      break;
    case(' '):
    if (followMouse)
      followMouse = false;
    else
      followMouse = true;
    break;
    case('c'):
      /* connect to the broadcaster */
      println("Sending connection packet to " + myBroadcastLocation.address());
      m = new OscMessage("/server/connect", new Object[0]);
      oscP5.flush(m, myBroadcastLocation);  
      break;
    case('d'):
      /* disconnect from the broadcaster */
      println("Sending disconnection packet to " + myBroadcastLocation.address());
      m = new OscMessage("/server/disconnect", new Object[0]);
      oscP5.flush(m, myBroadcastLocation);  
      connectionType = CONN_UNCONNECTED;
      break;
    case('h'):
      if (connectionType != CONN_SERVER) {
        println("Entering Host Mode");
        connectionType = CONN_SERVER;
        oscP5.stop();
        oscP5 = new OscP5(this, listenPort);
      } 
      else {
        println("Entering Client Mode");
        connectionType = CONN_UNCONNECTED;
        oscP5.stop();
        oscP5 = new OscP5(this, broadcastPort);
      }
      break;
  }
}

public void mousePressed() {
  if (!isInitializing) { 
    boolean dragging = false;
    mousePressedPos = mousePosition;
    
    for (Mirror mirror : mirrors) {
      if (mirror.isHovering(mousePressedPos)) {
        mirror.mouseOffset = PVector.sub(mousePressedPos, mirror.origin);
        mirror.locked = true;
        dragging = true;
      } 
      else {
        mirror.locked = false;
      }
    }
  }
}

public void mouseReleased() {

  for (Mirror mirror : mirrors) {
    mirror.locked = false;
  }
}

public void mouseMoved() {

  if (followMouse && !isInitializing) {
    float deltaY = mousePosition.y - rays.get(0).origin.y;
    float deltaX = mousePosition.x - rays.get(0).origin.x;
    rays.get(0).setAngle(degrees(atan2(deltaY, deltaX)));
    if (rays.get(0).angle < 0) {
      rays.get(0).setAngle( rays.get(0).angle += 360 );
    }
  }
}

public void mouseDragged() {
  if (!isInitializing) {
    // Update dragged mirrors
    for (Mirror mirror : mirrors) {
      if (mirror.locked == true) {
        mirror.setOrigin(PVector.sub(mousePosition, mirror.mouseOffset));
      }
    }
  }
}

//void mouseScrolled() {
//  if (mouseScroll > 0) {
//    mirrors.get(0).angle += PI/100;
//  } else {
//    mirrors.get(0).angle -= PI/100;
//  }
//}

public void mouseWheel(MouseEvent event) {
  if (!isInitializing) {
    float e = event.getAmount();
  
    for (Mirror mirror : mirrors) {
      if (PVector.dist(mousePosition, mirror.origin) < 20) {
        float angle = mirror.angle + e;
        
        if (angle >= 180)
          angle -= 360;
        else if (angle <= -180)
          angle += 360;
          
        mirror.setAngle(angle);

      }
    }
  }
}


public void oscEvent(OscMessage theOscMessage) {
  /* check if the address pattern fits any of our patterns */
  switch (connectionType) {
    case CONN_SERVER:
      if (theOscMessage.addrPattern().equals(connectPattern)) {
        connect(theOscMessage.netAddress().address());
      }
      else if (theOscMessage.addrPattern().equals(disconnectPattern)) {
        disconnect(theOscMessage.netAddress().address());
      } else if (theOscMessage.checkAddrPattern(ADDR_MIRRORANGLE)) {
        mirrors.get(theOscMessage.get(0).intValue()).setAngle(theOscMessage.get(1).floatValue());
      } else if (theOscMessage.checkAddrPattern(ADDR_MIRRORORIGIN)) {
        PVector temp = new PVector(theOscMessage.get(1).floatValue(),theOscMessage.get(2).floatValue());
        mirrors.get(theOscMessage.get(0).intValue()).setOrigin(temp);
        temp = null;
      } else if (theOscMessage.checkAddrPattern(ADDR_NEWENEMY)) {
        enemies.add(new Enemy( theOscMessage.get(0).floatValue(), theOscMessage.get(1).floatValue(), theOscMessage.get(2).floatValue(), ENEMY_SIZE ));
        sendMessage(theOscMessage);
      } else if (theOscMessage.checkAddrPattern(ADDR_NEWMIRROR)) {
        mirrors.add(new Mirror(theOscMessage.get(0).floatValue(), theOscMessage.get(1).floatValue(), theOscMessage.get(2).floatValue(), MIRROR_SIZE));
        sendMessage(theOscMessage);
      }
    break;
    
    case CONN_UNCONNECTED:
      if (theOscMessage.addrPattern().equals("/server/connected")) {
        connectionType = CONN_CLIENT;
        println("Switching to broadcast server: " + theOscMessage.netAddress().address());
        myBroadcastLocation = new NetAddress(theOscMessage.netAddress().address(), listenPort);
        clientIndex = theOscMessage.get(0).intValue();
        println("Client index is: " + clientIndex);
        screenOffsetX = clientIndex * screenW;
        
      }
    case CONN_CLIENT:
      if (theOscMessage.checkAddrPattern(ADDR_INIT)==true) {
        // Set initialization boolean to lock system from concurrent modification
        isInitializing = true;
        mirrors.clear();
        enemies.clear();
        followMouse = false;
      } else if (theOscMessage.checkAddrPattern(ADDR_INITDONE)==true) {
        isInitializing = false;
      } else if (theOscMessage.checkAddrPattern(ADDR_NEWRAY)==true) {
        rays.get(0).origin.x = theOscMessage.get(0).floatValue();
        rays.get(0).origin.y = theOscMessage.get(1).floatValue();
        rays.get(0).angle = theOscMessage.get(2).floatValue();
      } else if (theOscMessage.checkAddrPattern(ADDR_NEWMIRROR)==true) {
        mirrors.add(new Mirror(theOscMessage.get(0).floatValue(), theOscMessage.get(1).floatValue(), theOscMessage.get(2).floatValue(), MIRROR_SIZE));
      } else if (theOscMessage.checkAddrPattern(ADDR_NEWENEMY)==true) {
        enemies.add(new Enemy(theOscMessage.get(0).floatValue(), theOscMessage.get(1).floatValue(), theOscMessage.get(2).floatValue(), ENEMY_SIZE));
      } else if (theOscMessage.checkAddrPattern(ADDR_RAYANGLE)==true) {
        rays.get(0).angle = theOscMessage.get(0).floatValue();
      } else if (theOscMessage.checkAddrPattern(ADDR_MIRRORANGLE)) {
        mirrors.get(theOscMessage.get(0).intValue()).angle = theOscMessage.get(1).floatValue();
      } else if (theOscMessage.checkAddrPattern(ADDR_MIRRORORIGIN)) {
        mirrors.get(theOscMessage.get(0).intValue()).origin.x = theOscMessage.get(1).floatValue();
        mirrors.get(theOscMessage.get(0).intValue()).origin.y = theOscMessage.get(2).floatValue();
      }
    break;
  }

  
 
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  println(" values: " + theOscMessage.toString());
  println(" timetag: "+theOscMessage.timetag());
 
  /**
   * if pattern matching was not successful, then broadcast the incoming
   * message to all addresses in the netAddresList. 
   */
    //    oscP5.send(theOscMessage, myNetAddressList);

}

public void sendMessage(OscMessage myMessage) {
  if (connectionType == CONN_SERVER) {
    println("Server: Sending message: " + myMessage.toString());
    oscP5.send(myMessage, myNetAddressList);
  } else if (connectionType == CONN_CLIENT){
    println("Client: Sending message: " + myMessage.toString());
    oscP5.send(myMessage, myBroadcastLocation);
  }
}

private void intializeRemoteClient( NetAddress client ) {
  OscBundle bundle = new OscBundle();
  
  /* createa new osc message object */
  OscMessage myMessage = new OscMessage(ADDR_INIT);
  myMessage.add(100);
  
  /* add an osc message to the osc bundle */
  bundle.add(myMessage);
  
  /* Add initial laser */
  myMessage.clear();
  Ray laser = rays.get(0);
  myMessage.setAddrPattern(ADDR_NEWRAY);
  myMessage.add(laser.origin.x);
  myMessage.add(laser.origin.y);
  myMessage.add(laser.angle);
  bundle.add(myMessage);
  
  
  /* Add all mirrors */
  
  for (Mirror mirror : mirrors) {
    myMessage.clear();
    myMessage.setAddrPattern(ADDR_NEWMIRROR);
    myMessage.add(mirror.origin.x);
    myMessage.add(mirror.origin.y);
    myMessage.add(mirror.angle);
    bundle.add(myMessage);
  }

  /* Add all enemies */
  for (Enemy enemy : enemies) {
    myMessage.clear();
    myMessage.setAddrPattern(ADDR_NEWENEMY);
    myMessage.add(enemy.origin.x);
    myMessage.add(enemy.origin.y);
    myMessage.add(enemy.angle);
    bundle.add(myMessage);
  }
  
  /* Add game parameters */
  
  /* reset and clear the myMessage object for refill. */
  myMessage.clear();
  
  /* send end initializtion message */
  myMessage.setAddrPattern(ADDR_INITDONE);
  myMessage.add(200);
  bundle.add(myMessage);
  
  bundle.setTimetag(bundle.now() + 10000);
  /* send the osc bundle, containing 2 osc messages, to a remote location. */
  oscP5.send(bundle, client);
}

private void connect(String theIPaddress) {
  if (!myNetAddressList.contains(theIPaddress, broadcastPort)) {
    myNetAddressList.add(new NetAddress(theIPaddress, broadcastPort));
    println("### adding "+theIPaddress+" to the list.");
    // Send connected confirmation back to client
    println("Sending /server/connected to " + myNetAddressList.get(myNetAddressList.size()-1) );
    OscMessage responseMessage = new OscMessage("/server/connected");
    responseMessage.add(myNetAddressList.size());
    oscP5.send(responseMessage, myNetAddressList.get(myNetAddressList.size()-1));
    intializeRemoteClient( myNetAddressList.get(myNetAddressList.size()-1) );
  } 
  else {
    println("### "+theIPaddress+" is already connected.");
  }
  println("### currently there are "+myNetAddressList.list().size()+" remote locations connected.");
  // Send game setup
}


private void disconnect(String theIPaddress) {
  if (myNetAddressList.contains(theIPaddress, broadcastPort)) {
    myNetAddressList.remove(theIPaddress, broadcastPort);
    println("### removing "+theIPaddress+" from the list.");
  } 
  else {
    println("### "+theIPaddress+" is not connected.");
  }
  println("### currently there are "+myNetAddressList.list().size());
}

/**
@author Ryan Alexander 
*/
 
// Infinite Line Intersection
 
public PVector lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4)
{
  float bx = x2 - x1;
  float by = y2 - y1;
  float dx = x4 - x3;
  float dy = y4 - y3; 
  float b_dot_d_perp = bx*dy - by*dx;
  if(b_dot_d_perp == 0) {
    return null;
  }
  float cx = x3-x1; 
  float cy = y3-y1;
  float t = (cx*dy - cy*dx) / b_dot_d_perp; 
 
  return new PVector(x1+t*bx, y1+t*by); 
}

public PVector rayIntersection(Ray ray1, Mirror ray2) {
  return segIntersection( ray1.origin.x, ray1.origin.y, ray1.origin.x + ray1.distance * cos(radians(ray1.angle)), ray1.origin.y + ray1.distance * sin(radians(ray1.angle)), ray2.origin.x - ray2.radius * cos(radians(ray2.angle)), ray2.origin.y - ray2.radius * sin(radians(ray2.angle)), ray2.origin.x + ray2.radius * cos(radians(ray2.angle)), ray2.origin.y + ray2.radius * sin(radians(ray2.angle))); 
}
 
 
// Line Segment Intersection
 
public PVector segIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) 
{ 
  float bx = x2 - x1; 
  float by = y2 - y1; 
  float dx = x4 - x3; 
  float dy = y4 - y3;
  float b_dot_d_perp = bx * dy - by * dx;
  if(b_dot_d_perp == 0) {
    return null;
  }
  float cx = x3 - x1;
  float cy = y3 - y1;
  float t = (cx * dy - cy * dx) / b_dot_d_perp;
  if(t < 0 || t > 1) {
    return null;
  }
  float u = (cx * by - cy * bx) / b_dot_d_perp;
  if(u < 0 || u > 1) { 
    return null;
  }
  return new PVector(x1+t*bx, y1+t*by);
}

public float distOfPVectors( PVector pv1, PVector pv2) {
  return dist(pv1.x, pv1.y, pv2.x, pv2.y);
}

public boolean circleLineIntersect(float x1, float y1, float x2, float y2, float cx, float cy, float cr) {

  // Translate everything so that line segment start point to (0, 0)
  float a = x2-x1; // Line segment end point horizontal coordinate
  float b = y2-y1; // Line segment end point vertical coordinate
  float c = cx-x1; // Circle center horizontal coordinate
  float d = cy-y1; // Circle center vertical coordinate
  
  // Optional orientation computation
  boolean circleSideIsRight = false;
  if (d*a - c*b < 0) {
    // Circle center is on left side looking from (x0, y0) to (x1, y1)
    circleSideIsRight = true;
  }
    
  // Collision computation
  boolean startInside = false;
  boolean endInside = false;
  boolean middleInside = false;
  if ((d*a - c*b)*(d*a - c*b) <= cr*cr*(a*a + b*b)) {
    // Collision is possible
    if (c*c + d*d <= cr*cr) {
      // Line segment start point is inside the circle
      startInside = true;
    }
    if ((a-c)*(a-c) + (b-d)*(b-d) <= cr*cr) {
      // Line segment end point is inside the circle
      endInside = true;
    }
    if (!startInside && !endInside && c*a + d*b >= 0 && c*a + d*b <= a*a + b*b) {
      // Middle section only
      middleInside = true;
    }
  }
  
  if (startInside || endInside || middleInside) {
    return true;
  }
  return false;
}
class Enemy {
  PVector origin;
  float angle, radius;
  boolean hit;
  Enemy ( float x, float y, float angleInDegrees, float radius ) {
    origin = new PVector(x, y);
    angle = angleInDegrees;
    this.radius = radius;
    hit = false;
  }
  
  public void draw() {
    pushMatrix();
    pushStyle();
    translate( origin.x, origin.y );
    if (hit) {
      fill(255, 0, 0);
    } else {
      fill(255);
    }
    ellipse( 0, 0, radius, radius );
    line( 0, 0, cos(radians(angle)), sin(radians(angle)));
    popStyle();
    popMatrix();
  }
  
  public boolean checkCollision(Ray ray) {
    
//    For debugging bad collisions
//    pushStyle();
//    fill(255,255,0);
//    ellipse(ray.origin.x, ray.origin.y, 5, 5);
//    ellipse(ray.endPoint().x, ray.endPoint().y, 5, 5);
//    ellipse(origin.x, origin.y, 5, 5);
//    popStyle();
    
    return circleLineIntersect(ray.origin.x, ray.origin.y, ray.endPoint().x, ray.endPoint().y, origin.x, origin.y, radius );
  }
  
}
class Mirror extends Ray {
  float radius;
  boolean hover,locked;
  PVector mouseOffset;
  Mirror( float x1, float y1, float angleInDegrees, float size ) {
    super(x1, y1, angleInDegrees);
    radius = size;
    hover = false;
    locked = false;
    mouseOffset = new PVector(0,0);
  } 
  
  public PVector startPoint() {
    return new PVector(origin.x -radius*cos(radians(angle)),origin.y -radius*sin(radians(angle)));
  }
  
  public PVector endPoint() {
    return new PVector(origin.x + radius*cos(radians(angle)),origin.y + radius*sin(radians(angle)));
  }
  
  public void draw() {
    pushMatrix();
    pushStyle();
    translate( this.origin.x, this.origin.y );

    if (locked){
      stroke(0, 0, 255);
    } else if (hover) {
      stroke(0, 255, 0);
      pushStyle();
      noFill();
      stroke(0xff92F2FF);
      strokeWeight(3);
      ellipse(0,0, 20, 20);
      popStyle();
    } else {
      stroke(0);
    }
    
    line(-radius*cos(radians(angle)), -radius*sin(radians(angle)), radius*cos(radians(angle)), radius*sin(radians(angle)));

    fill(0);
    text(this.angle, 0, 0  );
    popStyle();
    popMatrix();
  }
  
  public boolean isHovering(PVector position) {
    
    PVector startPoint = new PVector(origin.x-radius*cos(radians(angle)), origin.y-radius*sin(radians(angle)));
    PVector endPoint = new PVector(origin.x+radius*cos(radians(angle)), origin.y+radius*sin(radians(angle)));
    float lineC = distOfPVectors(startPoint, endPoint);
    float lineA = distOfPVectors(startPoint, position);
    float lineB = distOfPVectors(endPoint, position);
    float distance = (lineA + (lineB - lineA)/2)-100;
    
    if (distance < HOVER_DISTANCE) {
      return true;
    }
    return false;
  }
 
  public void setAngle(float newAngle) {
    OscMessage myMessage = new OscMessage(ADDR_MIRRORANGLE);
    int index = mirrors.indexOf(this);
    myMessage.add(index);
    myMessage.add(newAngle);
    sendMessage(myMessage);
    
    if (connectionType <= CONN_SERVER) {
      this.angle = newAngle;
    }
  }
 
  public void setOrigin(PVector newOrigin) {
    OscMessage myMessage = new OscMessage(ADDR_MIRRORORIGIN);
    int index = mirrors.indexOf(this);
    myMessage.add(index);
    myMessage.add(newOrigin.x);
    myMessage.add(newOrigin.y);
    sendMessage(myMessage);
    
    if (connectionType <= CONN_SERVER) {
      this.origin = newOrigin;
    }
  } 
}

class Ray {
  PVector origin;
  float angle, distance;
  Ray( float x1, float y1, float angleInDegrees ){
    origin = new PVector(x1, y1);
    angle = angleInDegrees;
    distance = rayDist;
  }
  
  public PVector endPoint() {
    PVector endPoint = new PVector(origin.x + distance*cos(radians(angle)), origin.y + distance*sin(radians(angle)));
    return endPoint;
  }
  
  public void setAngle(float newAngle) {
    this.angle = newAngle;
    if (connectionType >= CONN_SERVER ) { 
      OscMessage myMessage = new OscMessage(ADDR_RAYANGLE);
      myMessage.add(newAngle);
      sendMessage(myMessage);
    }
  }
  
  public void setX(float x) {
    this.origin.x = x;
    if (connectionType >= CONN_SERVER) {
      OscMessage myMessage = new OscMessage(ADDR_RAYX);
      myMessage.add(x);
      sendMessage(myMessage);
    }
  }
  
  public void setY(float y) {
    this.origin.y = y;
    if (connectionType == CONN_SERVER) {
      OscMessage myMessage = new OscMessage(ADDR_RAYY);
      myMessage.add(y);
      oscP5.send(myMessage, myNetAddressList);
    }
  }
    
  public void draw() {
    pushMatrix();
    translate( this.origin.x, this.origin.y );
    line(0,0, distance*cos(radians(angle)), distance*sin(radians(angle)));
    pushStyle();
    fill(0);
    text(this.angle, 0, 0  );
    popStyle();
    popMatrix();
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "newLaserGame" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
