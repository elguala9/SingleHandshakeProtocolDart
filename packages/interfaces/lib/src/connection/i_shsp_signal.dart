import 'package:shsp_types/shsp_types.dart';

abstract interface class IHandshakeInitiatorSignalHandler {
  PeerInfo? getPublicIPv4();
  PeerInfo? getPublicIPv6();
  PeerInfo? getLocalIPv4();
  PeerInfo? getLocalIPv6();
  String? getPublicKey();
  int getSecondsToNextHandshake(); // -1 no handshake planned
  // should throw if no handshake planned
  // ...existing code...
  static IHandshakeInitiatorSignalHandler getMySignal() {
    throw UnimplementedError();
  }
}