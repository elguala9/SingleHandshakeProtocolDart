abstract interface class IHandshakeTime {
  int getHandshakeTimeframe();
  DateTime getStartHandshakeTime();
  DateTime getEndHandshakeTime();
  int getSecondsToNextHandshake(); // -1 no handshake planned
}
