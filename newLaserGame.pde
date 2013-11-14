ArrayList<Ray> rays;
ArrayList<Mirror> mirrors;
PVector mousePressedPos;
PVector mouseReleasedPos;
int screenW = 1600;
int screenH = 500;
static int rayDist = (int)sqrt((float)(Math.pow(1600,2) + Math.pow(500,2)));



class Ray {
  PVector origin;
  float angle, distance;
  Ray( float x1, float y1, float angleInDegrees ){
    origin = new PVector(x1, y1);
    angle = angleInDegrees;
    distance = rayDist;
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
  rays = new ArrayList<Ray>();
  smooth();
  Ray newRay = new Ray(200.0, 200.0, 0);
  rays.add(newRay);
  mirrors.add(new Mirror(1000, 300, 45, 100));
}

void draw() {
  background(255);
    
    int numRays = rays.size()-1;
    
    for (int j=0; j<numRays; j++) {
      Ray ray = rays.get(j);
      for (int i=0; i<mirrors.size(); i++) {
//        mirrors.get(i).draw();
        PVector intersection = rayIntersection(ray, mirrors.get(i));
        if (intersection != null) {
          ellipse( intersection.x, intersection.y, 10, 10);
          Ray reflection = new Ray( intersection.x, intersection.y, reflectionAngleInDegrees( ray, mirrors.get(i), intersection ));
          rays.add(reflection);
          numRays++;
          ray.distance = dist(ray.origin.x, ray.origin.y, intersection.x, intersection.y);
        } else {
          ray.distance = rayDist;
        }
      }

    }
    
    pushStyle();
    stroke(255,0,0);
    for (Ray ray : rays) {

      ray.draw();
    }
    popStyle();


    for (Mirror mirror : mirrors) {
      mirror.draw();
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
  
  pushStyle();
  fill(0);
  stroke(0);
  text("Incident angle: " + incidentAngle + " Bounce angle: " + bounceAngle, width/2, height - 20); 
  popStyle();
  return -bounceAngle;
}

void mouseClicked() { 
  mousePressedPos = new PVector(mouseX, mouseY);
  Mirror mirror = new Mirror(mouseX, mouseY, 45, 100);
  mirrors.add(mirror);
}

void mouseReleased() {

}

void mouseMoved() {
  float deltaY = mouseY - rays.get(0).origin.y;
  float deltaX = mouseX - rays.get(0).origin.x;
  rays.get(0).angle = degrees(atan2(deltaY, deltaX));
  if (rays.get(0).angle < 0) {
    rays.get(0).angle += 360;
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
  mirrors.get(0).angle += e;
  if (mirrors.get(0).angle >= 180)
    mirrors.get(0).angle -= 360;
  else if (mirrors.get(0).angle <= -180)
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
