Ray newRay;
ArrayList mirrors;

int screenW = 1600;
int screenH = 500;
int rayDist = (int)sqrt((float)(Math.pow(1600,2) + Math.pow(500,2)));

void setup() {
  size( 1600, 500 );
  mirrors = new ArrayList();
  smooth();
  newRay = new Ray(10.0, 10.0, PI);
  mirrors.add(new Ray(1000, 300, PI*0.75));
}

void draw() {
  background(255);
  newRay.draw();
  for (int i=0; i<mirrors.size()-1; i++) { 
    Ray ray = (Ray) mirrors.get(i);
    ray.draw();
  }
  
//  line(300, 500, 800, 300);
//  line(800, 500, 300, 300);
//  
//  PVector intersection = lineIntersection(300, 500, 800, 300, 800, 500, 300, 300);

  PVector intersection = rayIntersection(newRay, mirrors.get(0));
  if (intersection != null) {
    ellipse( intersection.x, intersection.y, 10, 10);
    Ray reflection = new Ray( intersection.x, intersection.y, reflectionAngleInRadians( newRay, mirrors.get(0) ));
//    Ray normalAngle = new Ray( intersection.x, intersection.y, bounceRay.angle - PI/2);
//    normalAngle.draw();
    reflection.draw();
  }
//  line(1000, 300, 1200, 100);
}

class Mirror {
  PVector origin, heading;
  float angle, radius;
  Mirror ( float x1, float y1, float angleInRadians ) {
    origin = new PVector(x1, y1);
    heading = new PVector(cos(angleInRadians), sin(angleInRadians));
    angle = angleInRadians;
  }
  
}

class Ray {
  PVector origin, heading;
  float angle;
  Ray( float x1, float y1, float angleInRadians ){
    origin = new PVector(x1, y1);
    heading = new PVector(cos(angleInRadians), sin(angleInRadians));
    this.angle = angleInRadians;
  }
  
  void draw() {
    pushMatrix();
    pushStyle();
    translate( this.origin.x, this.origin.y );
    line(0,0, rayDist*cos(angle), rayDist*sin(angle));
    fill(0);
    text(this.angle, 0, 0  );
    popStyle();
    popMatrix();
  }
}

float reflectionAngleInRadians( Ray incoming, Ray surface ) {
  float angle = 180 - (incoming.angle * 180/PI) - 2 * (surface.angle * 180/PI);
  
  if (angle < 0) {
    angle += 360;
  }
  
  // Convert angle back to degrees
  angle = angle * PI/180;
  
  return angle;
}

void mouseClicked() { 
  
}

void mouseReleased() {
}

void mouseMoved() {
  float deltaY = mouseY - newRay.origin.y;
  float deltaX = mouseX - newRay.origin.x;
  newRay.angle = atan2(deltaY, deltaX);
}


void mouseScrolled() {
  if (mouseScroll > 0) {
    mirrors.get(0).angle += PI/100;
  } else {
    mirrors.get(0).angle -= PI/100;
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

PVector rayIntersection(Ray ray1, Ray ray2) {
  return segIntersection( ray1.origin.x, ray1.origin.y, ray1.origin.x + rayDist * cos(ray1.angle), ray1.origin.y + rayDist * sin(ray1.angle), ray2.origin.x, ray2.origin.y, ray2.origin.x + rayDist * cos(ray2.angle), ray2.origin.y + rayDist * sin(ray2.angle)); 
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

