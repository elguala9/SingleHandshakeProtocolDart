import 'dart:io';

import '../../types/callback_types.dart';
import '../../types/instance_profile.dart';
import '../../types/internet_address_converter.dart';
import '../../types/peer_types.dart';
import '../../types/remote_info.dart';
import '../../types/socket_profile.dart';

abstract interface class IHandshakeIP {
  PeerInfo? getPublicIPv4();
  PeerInfo? getPublicIPv6();
  PeerInfo? getLocalIPv4();
  PeerInfo? getLocalIPv6();
}

// assure the ownership of the handshake (to avoid man in the middle)
abstract interface class IHandshakeOwnership {
  // return a cripted string (cripted with the other peer public key), the string is a nonce signed with a private key of this peer (the other peer need the public key to verify the signature)
  String? sign();
}

abstract interface class IHandshakeTime {
  int getHandshakeTimeframe();
  DateTime getStartHandshakeTime();
  DateTime getEndHandshakeTime();
  int getSecondsToNextHandshake(); // -1 no handshake planned
}

abstract class IHandshake
    implements IHandshakeOwnership, IHandshakeIP, IHandshakeTime {}

external IHandshake getMySignal(RawDatagramSocket socket);
external IHandshake processSignal(String signal);
