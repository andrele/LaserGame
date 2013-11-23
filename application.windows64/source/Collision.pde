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
