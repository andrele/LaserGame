class Client extends NetAddress {
  int id;
  PVector screenSize;
  Client( String ip, int port, int resX, int resY ) {
    super( ip, port);
    id = -1;
    screenSize = new PVector(resX, resY);
  }
}
