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
