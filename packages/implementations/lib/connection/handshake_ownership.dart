//import 'package:cryptdart/cryptdart.dart';
import 'package:shsp_interfaces/src/connection/i_shsp_handshake.dart';

typedef InputHandshakeOwnership = ({
  String signedNonce,
});

class HandshakeOwnership implements IHandshakeOwnership {
  final String? signedNonce;

  HandshakeOwnership(this.signedNonce);

  @override
  String? sign() => signedNonce;
}
