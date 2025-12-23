//import 'package:cryptdart/cryptdart.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

typedef InputHandshakeOwnership = ({
  String signedNonce,
});

class HandshakeOwnership implements IHandshakeOwnership {
  final String? signedNonce;

  HandshakeOwnership(this.signedNonce);

  @override
  String? sign() => signedNonce;
}
