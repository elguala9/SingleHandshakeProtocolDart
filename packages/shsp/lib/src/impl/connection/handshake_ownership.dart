//import 'package:cryptdart/cryptdart.dart';
import '../../interfaces/connection/i_shsp_handshake.dart';

typedef InputHandshakeOwnership = ({
  String signedNonce,
});

class HandshakeOwnership implements IHandshakeOwnership {
  HandshakeOwnership(this.signedNonce);

  final String? signedNonce;

  @override
  String? sign() => signedNonce;
}
