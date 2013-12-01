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
  
  void setAngle(float newAngle) {
    this.angle = newAngle;
    if (connectionType >= CONN_SERVER ) { 
      OscMessage myMessage = new OscMessage(ADDR_RAYANGLE);
      myMessage.add(newAngle);
      sendMessage(myMessage);
    }
  }
  
  void setX(float x) {
    this.origin.x = x;
    if (connectionType >= CONN_SERVER) {
      OscMessage myMessage = new OscMessage(ADDR_RAYX);
      myMessage.add(x);
      sendMessage(myMessage);
    }
  }
  
  void setY(float y) {
    this.origin.y = y;
    if (connectionType == CONN_SERVER) {
      OscMessage myMessage = new OscMessage(ADDR_RAYY);
      myMessage.add(y);
      oscP5.send(myMessage, myNetAddressList);
    }
  }
    
  void draw() {
    src.pushMatrix();
    src.translate( this.origin.x, this.origin.y );
    src.line(0,0, distance*cos(radians(angle)), distance*sin(radians(angle)));
    src.pushStyle();
    src.fill(0);
    src.text(this.angle, 0, 0  );
    src.popStyle();
    src.popMatrix();
  }
}
