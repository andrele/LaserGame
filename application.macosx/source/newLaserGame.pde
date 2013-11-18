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
static int rayDist = (int)sqrt((float)(Math.pow(1600,2) + Math.pow(500,2)));

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
  
  void draw() {
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
  
  boolean checkCollision(Ray ray) {
    
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

class Ray {
  PVector origin;
  float angle, distance;
  Ray( float x1, float y1, float angleInDegrees ){
    origin = new PVector(x1, y1);
    angle = angleInDegrees;
    distance = rayDist;
  }
  
  PVector endPoint() {
    PVector endPoint = new PVector(origin.x + distance*cos(radians(angle)), origin.y + distance*sin(radians(angle)));
    return endPoint;
  }
  
  void draw() {
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
  
  PVector startPoint() {
    return new PVector(origin.x -radius*cos(radians(angle)),origin.y -radius*sin(radians(angle)));
  }
  
  PVector endPoint() {
    return new PVector(origin.x + radius*cos(radians(angle)),origin.y + radius*sin(radians(angle)));
  }
  
  void draw() {
    pushMatrix();
    pushStyle();
    translate( this.origin.x, this.origin.y );

    if (locked){
      stroke(0, 0, 255);
    } else if (hover) {
      stroke(0, 255, 0);
      pushStyle();
      noFill();
      stroke(#92F2FF);
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
  
  boolean isHovering(PVector position) {
    
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
}


void setup() {
  size( 1600, 500 );
  ellipseMode(RADIUS);
  mousePressedPos = new PVector(0,0);
  mousePosition = new PVector(mouseX, mouseY);
  mirrors = new ArrayList<Mirror>();
  rays = new ArrayList<Ray>();
  enemies = new ArrayList<Enemy>();
  smooth();
  laser = new Ray(200.0, 200.0, 0);
  mirrors.add(new Mirror(1000, 300, 45, 100));
}

float distOfPVectors( PVector pv1, PVector pv2) {
  return dist(pv1.x, pv1.y, pv2.x, pv2.y);
}

void update() {
  // Get the initial size of Ray array
  int numRays = 1;
  rays.clear();
  rays.add(laser);
  numBounces = 0;
  
  // Clear all previous hit states
  enemiesHit = 0;
  for (Enemy enemy : enemies){
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
    } else if ( ray.distance < rayDist ) {
        ray.distance = rayDist;
        println("Resetting distance");
    }
    
    // Check for enemy collisions
    for (Enemy enemy : enemies) {
      if (enemy.checkCollision(ray)) {
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
    
  update();
    
  // Draw rays
  pushStyle();
  stroke(255,0,0);
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
  text("Enemies hit: " + enemiesHit + "/" + enemies.size() + " Bounces: " + numBounces, 10, 35);
  pushStyle();
  textSize(18);
  textAlign(CENTER);
  text("Press E to spawn new Enemy. Press M to spawn new Mirror. Press SPACEBAR to lock Laser.\nClick and drag mirrors to move. MouseWheel to rotate mirrors.", width/2, height - 35);
  popStyle(); 
  popStyle();
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

void keyPressed(){
  if (key == 'e') {
    Enemy newEnemy = new Enemy( mouseX, mouseY, 20, 20);
    enemies.add(newEnemy);
  } else if (key == 'm') {
    Mirror mirror = new Mirror(mouseX, mouseY, 45, 100);
    mirrors.add(mirror);
  } else if (key == ' ') {
    if (followMouse)
      followMouse = false;
    else
      followMouse = true;
  }
}

void mousePressed() { 
  boolean dragging = false;
  mousePressedPos = new PVector(mouseX, mouseY);
 
  for (Mirror mirror : mirrors) {
    if (mirror.isHovering(mousePressedPos)){
      mirror.mouseOffset = PVector.sub(mousePressedPos, mirror.origin);
      mirror.locked = true;
      dragging = true;
    } else {
      mirror.locked = false;
    }
  }
}

void mouseReleased() {
  
  for (Mirror mirror : mirrors) {
    mirror.locked = false;
  }
  
}

void mouseMoved() {
  
  if (followMouse) {
    float deltaY = mouseY - rays.get(0).origin.y;
    float deltaX = mouseX - rays.get(0).origin.x;
    rays.get(0).angle = degrees(atan2(deltaY, deltaX));
    if (rays.get(0).angle < 0) {
      rays.get(0).angle += 360;
    }
  }
  

  
}

void mouseDragged() {
  // Update dragged mirrors
  for (Mirror mirror : mirrors) {
    if (mirror.locked == true) {
      mirror.origin = PVector.sub(mousePosition, mirror.mouseOffset);
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
  float e = event.getAmount();
  
  for (Mirror mirror : mirrors) {
    if (PVector.dist(mousePosition, mirror.origin) < 20){
      mirror.angle += e;
      if (mirror.angle >= 180)
        mirror.angle -= 360;
      else if (mirror.angle <= -180)
        mirror.angle += 360;
    }
  }
  
  
}


/**
@author Ryan Alexander 
*/
 
// Infinite Line Intersection
 
PVector lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4)
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

PVector rayIntersection(Ray ray1, Mirror ray2) {
  return segIntersection( ray1.origin.x, ray1.origin.y, ray1.origin.x + ray1.distance * cos(radians(ray1.angle)), ray1.origin.y + ray1.distance * sin(radians(ray1.angle)), ray2.origin.x - ray2.radius * cos(radians(ray2.angle)), ray2.origin.y - ray2.radius * sin(radians(ray2.angle)), ray2.origin.x + ray2.radius * cos(radians(ray2.angle)), ray2.origin.y + ray2.radius * sin(radians(ray2.angle))); 
}
 
 
// Line Segment Intersection
 
PVector segIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) 
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




boolean circleLineIntersect(float x1, float y1, float x2, float y2, float cx, float cy, float cr) {

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
