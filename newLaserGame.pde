// Server stuff
import oscP5.*;
import netP5.*;
import java.net.*;
import java.util.Enumeration;

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
int screenW = 1600;
int screenH = 500;
static int rayDist = (int)sqrt((float)(Math.pow(1600, 2) + Math.pow(500, 2)));

String getBroadcastAddress() {
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

void setup() {
  // Start all instances to Client by default
  //  oscP5 = new OscP5(this, listenPort); // Server setup
  // Commented out for debugging
//  myBroadcastLocation = new NetAddress(getBroadcastAddress(), listenPort);
  myBroadcastLocation = new NetAddress("127.0.0.1", listenPort);
  oscP5 = new OscP5(this, broadcastPort);
  println("Broadcast address: " + getBroadcastAddress());

  size( 1600, 500 );
  ellipseMode(RADIUS);
  mousePressedPos = new PVector(0, 0);
  mousePosition = new PVector(mouseX, mouseY);
  mirrors = new ArrayList<Mirror>();
  rays = new ArrayList<Ray>();
  enemies = new ArrayList<Enemy>();
  fill(0);
  smooth();
  laser = new Ray(200.0, 200.0, 0);
  mirrors.add(new Mirror(1000, 300, 45, MIRROR_SIZE));
}



void update() {
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

void draw() {
  background(255);
  mousePosition.x = mouseX;
  mousePosition.y = mouseY;

  if (!isInitializing) {
    update();
  
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


float reflectionAngleInDegrees( Ray incoming, Ray surface, PVector intersection ) {

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

void keyPressed() {
  OscMessage m;
  switch (key) {
    case('e'):
    Enemy newEnemy = new Enemy( mouseX, mouseY, 20, ENEMY_SIZE);
    enemies.add(newEnemy);
    break;
    case('m'):
    Mirror mirror = new Mirror(mouseX, mouseY, 45, MIRROR_SIZE);
    mirrors.add(mirror);
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

void mousePressed() {
  if (!isInitializing) { 
    boolean dragging = false;
    mousePressedPos = new PVector(mouseX, mouseY);
    
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

void mouseReleased() {

  for (Mirror mirror : mirrors) {
    mirror.locked = false;
  }
}

void mouseMoved() {

  if (followMouse && !isInitializing) {
    float deltaY = mouseY - rays.get(0).origin.y;
    float deltaX = mouseX - rays.get(0).origin.x;
    rays.get(0).setAngle(degrees(atan2(deltaY, deltaX)));
    if (rays.get(0).angle < 0) {
      rays.get(0).setAngle( rays.get(0).angle += 360 );
    }
  }
}

void mouseDragged() {
  if (!isInitializing) {
    // Update dragged mirrors
    for (Mirror mirror : mirrors) {
      if (mirror.locked == true) {
        mirror.origin = PVector.sub(mousePosition, mirror.mouseOffset);
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

void mouseWheel(MouseEvent event) {
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


void oscEvent(OscMessage theOscMessage) {
  /* check if the address pattern fits any of our patterns */
  switch (connectionType) {
    case CONN_SERVER:
      if (theOscMessage.addrPattern().equals(connectPattern)) {
        connect(theOscMessage.netAddress().address());
      }
      else if (theOscMessage.addrPattern().equals(disconnectPattern)) {
        disconnect(theOscMessage.netAddress().address());
      } else if (theOscMessage.checkAddrPattern(ADDR_MIRRORANGLE)) {
        mirrors.get(theOscMessage.get(0).intValue()).angle = theOscMessage.get(1).floatValue();

      }
    break;
    
    case CONN_UNCONNECTED:
      if (theOscMessage.addrPattern().equals("/server/connected")) {
        connectionType = CONN_CLIENT;
        println("Switching to broadcast server: " + theOscMessage.netAddress().address());
        myBroadcastLocation = new NetAddress(theOscMessage.netAddress().address(), listenPort);
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
    oscP5.send(myMessage, myNetAddressList);
  } else if (connectionType == CONN_CLIENT){
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
    responseMessage.add(200);
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

