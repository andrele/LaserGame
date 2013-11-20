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
