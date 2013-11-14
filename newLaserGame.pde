Ray newRay;
ArrayList<Mirror> mirrors;
PVector mousePressedPos;
PVector mouseReleasedPos;
int screenW = 1600;
int screenH = 500;
int rayDist = (int)sqrt((float)(Math.pow(1600,2) + Math.pow(500,2)));



class Ray {
  PVector origin, heading;
  float angle;
  Ray( float x1, float y1, float angleInDegrees ){
    origin = new PVector(x1, y1);
    heading = new PVector(cos(radians(angleInDegrees)), sin(radians(angleInDegrees)));
    angle = angleInDegrees;
  }
  
  void draw() {
    pushMatrix();
    translate( this.origin.x, this.origin.y );
    line(0,0, rayDist*cos(radians(angle)), rayDist*sin(radians(angle)));
    pushStyle();
    fill(0);
    text(this.angle, 0, 0  );
    popStyle();
    popMatrix();
  }
}

class Mirror extends Ray {
  float radius;
  Mirror( float x1, float y1, float angleInDegrees, float size ) {
    super(x1, y1, angleInDegrees);
    radius = size;
  } 
  
  void draw() {
    pushMatrix();
    translate( this.origin.x, this.origin.y );
    line(-radius*cos(radians(angle)), -radius*sin(radians(angle)), radius*cos(radians(angle)), radius*sin(radians(angle)));
    pushStyle();
    fill(0);
    text(this.angle, 0, 0  );
    popStyle();
    popMatrix();
  }
}


void setup() {
  size( 1600, 500 );
  mousePressedPos = new PVector(0,0);
  mirrors = new ArrayList<Mirror>();
  smooth();
  newRay = new Ray(200.0, 200.0, 0);
  mirrors.add(new Mirror(1000, 300, 45, 100));
}

void draw() {
  background(255);
  pushStyle();
  stroke(255,0,0);
  newRay.draw();
  popStyle();
  for (int i=0; i<mirrors.size(); i++) {
    
    mirrors.get(i).draw();
    
    PVector intersection = rayIntersection(newRay, mirrors.get(i));
    if (intersection != null) {
      ellipse( intersection.x, intersection.y, 10, 10);
      Ray reflection = new Ray( intersection.x, intersection.y, reflectionAngleInDegrees( newRay, mirrors.get(i), intersection ));
//    Ray normalAngle = new Ray( intersection.x, intersection.y, bounceRay.angle - PI/2);
//    normalAngle.draw();
      pushStyle();
      stroke(255,0,0);
      reflection.draw();
      popStyle();
    }
  }
  
//  line(300, 500, 800, 300);
//  line(800, 500, 300, 300);
//  
//  PVector intersection = lineIntersection(300, 500, 800, 300, 800, 500, 300, 300);

//  line(1000, 300, 1200, 100);
}



float reflectionAngleInDegrees( Ray incoming, Ray surface, PVector intersection ) {

  float incidentAngle = incoming.angle;
  
  float bounceAngle = 180 - incidentAngle - surface.angle;
  
  
  if (bounceAngle < 0) {
    bounceAngle += 360;
  }
  
  text("Bounce angle: " + bounceAngle, width/2, height - 20); 
  return bounceAngle;
}

void mouseClicked() { 
  mousePressedPos = new PVector(mouseX, mouseY);
  Mirror mirror = new Mirror(mouseX, mouseY, 45, 100);
  mirrors.add(mirror);
}

void mouseReleased() {

}

void mouseMoved() {
  float deltaY = mouseY - newRay.origin.y;
  float deltaX = mouseX - newRay.origin.x;
  newRay.angle = degrees(atan2(deltaY, deltaX));
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
  mirrors.get(0).angle += e;
  if (mirrors.get(0).angle >= 360)
    mirrors.get(0).angle -= 360;
  else if (mirrors.get(0).angle <= 0)
    mirrors.get(0).angle += 360;
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
  return segIntersection( ray1.origin.x, ray1.origin.y, ray1.origin.x + rayDist * cos(radians(ray1.angle)), ray1.origin.y + rayDist * sin(radians(ray1.angle)), ray2.origin.x - ray2.radius * cos(radians(ray2.angle)), ray2.origin.y - ray2.radius * sin(radians(ray2.angle)), ray2.origin.x + ray2.radius * cos(radians(ray2.angle)), ray2.origin.y + ray2.radius * sin(radians(ray2.angle))); 
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
