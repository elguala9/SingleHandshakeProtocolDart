//import 'package:cryptdart/cryptdart.dart';
import '../../interfaces/connection/i_shsp_handshake.dart';
import '../../interfaces/exceptions/shsp_exceptions.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_instance.dart';
import '../../interfaces/i_shsp_instance_handler.dart';
import '../../interfaces/i_shsp_peer.dart';
import '../../interfaces/i_shsp_socket.dart';

typedef InputHandshakeOwnership = ({
  String signedNonce,
});

class HandshakeOwnership implements IHandshakeOwnership {
  final String? signedNonce;

  HandshakeOwnership(this.signedNonce);

  @override
  String? sign() => signedNonce;
}
