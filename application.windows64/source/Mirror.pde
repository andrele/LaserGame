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
    src.pushMatrix();
    src.pushStyle();
    src.translate( this.origin.x, this.origin.y );

    if (locked){
      src.stroke(0, 0, 255);
    } else if (hover) {
      src.stroke(0, 255, 0);
      src.pushStyle();
      src.noFill();
      src.stroke(#92F2FF);
      src.strokeWeight(3);
      src.ellipse(0,0, 20, 20);
      src.popStyle();
    } else {
      src.stroke(255);
    }
    
    src.line(-radius*cos(radians(angle)), -radius*sin(radians(angle)), radius*cos(radians(angle)), radius*sin(radians(angle)));

    src.fill(0);
    src.text(this.angle, 0, 0  );
    src.popStyle();
    src.popMatrix();
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
 
  void setAngle(float newAngle) {
    OscMessage myMessage = new OscMessage(ADDR_MIRRORANGLE);
    int index = mirrors.indexOf(this);
    myMessage.add(index);
    myMessage.add(newAngle);
    sendMessage(myMessage);
    
    if (connectionType <= CONN_SERVER) {
      this.angle = newAngle;
    }
  }
 
  void setOrigin(PVector newOrigin) {
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

