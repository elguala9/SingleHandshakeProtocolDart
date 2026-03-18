import 'dart:io';

import 'package:meta/meta.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_socket.dart';
import '../../types/peer_types.dart';

import 'shsp_peer.dart';
import '../socket/core/shsp_socket_singleton.dart';

/// A [ShspPeer] that automatically uses the global [ShspSocketSingleton] socket.
///
/// ## Confronto con [ShspPeer]
/// - [ShspPeer]: richiede un [IShspSocket] esplicito come parametro
/// - [AutoShspPeer]: ottiene il socket automaticamente dal [ShspSocketSingleton]
///
/// Possono coesistere più istanze di [AutoShspPeer], ognuna per un remote peer
/// diverso, condividendo lo stesso socket globale sottostante.
///
/// ## Esempio
/// ```dart
/// // Opzionale: inizializza il singleton prima (con parametri specifici)
/// await ShspSocketSingleton.getInstance(
///   address: InternetAddress.anyIPv4,
///   port: 9000,
/// );
///
/// // Crea peer senza passare il socket
/// final peer = await AutoShspPeer.create(
///   remotePeer: PeerInfo(address: remoteAddress, port: remotePort),
/// );
/// ```
class AutoShspPeer extends ShspPeer {
  AutoShspPeer._({
    required super.remotePeer,
    required super.socket,
    super.messageCallback,
    ShspSocketSingleton? singleton,
  }) {
    if (singleton != null) {
      // Register to be notified when the singleton socket changes
      singleton.socketChangedCallback.register((newSocket) {
        // Re-register this peer's callback with the new socket
        newSocket.setMessageCallback(remotePeer, socketCallbackFunction);
      });
    }
  }

  /// Factory solo per i test — consente di iniettare un socket esplicito.
  ///
  /// Usare questo constructor nelle suite di test di compliance (es. testIShspPeer)
  /// dove i test creano socket dedicati. Non usare in produzione.
  @visibleForTesting
  factory AutoShspPeer.withSocket({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    MessageCallback? messageCallback,
  }) =>
      AutoShspPeer._(
        remotePeer: remotePeer,
        socket: socket,
        messageCallback: messageCallback,
      );

  /// Crea un [AutoShspPeer] per comunicare con [remotePeer].
  ///
  /// Chiama internamente [ShspSocketSingleton.getInstance] per ottenere (o
  /// creare) il socket globale. I parametri opzionali [address], [port] e
  /// [compressionCodec] vengono passati a [ShspSocketSingleton.getInstance] e
  /// sono rilevanti solo se il singleton non è ancora stato inizializzato;
  /// se il singleton è già attivo, vengono ignorati da [ShspSocketSingleton].
  ///
  /// Parametri:
  ///   - [remotePeer]: Indirizzo e porta del peer remoto
  ///   - [address]: Indirizzo locale per il bind del socket (default: anyIPv4)
  ///   - [port]: Porta locale (default: 0 — efimera)
  ///   - [compressionCodec]: Codec di compressione (default: GZipCodec)
  ///   - [messageCallback]: Callback messaggi pre-configurato (opzionale)
  static Future<AutoShspPeer> create({
    required PeerInfo remotePeer,
    InternetAddress? address,
    int? port,
    ICompressionCodec? compressionCodec,
    MessageCallback? messageCallback,
  }) async {
    final singleton = await ShspSocketSingleton.getInstance(
      address: address,
      port: port,
      compressionCodec: compressionCodec,
    );

    return AutoShspPeer._(
      remotePeer: remotePeer,
      socket: singleton.socket,
      messageCallback: messageCallback,
      singleton: singleton,
    );
  }

  /// Chiude questo peer (rimuove il suo callback dal socket condiviso).
  ///
  /// Il [ShspSocketSingleton] viene intenzionalmente lasciato aperto, così
  /// gli altri peer che condividono lo stesso socket non sono influenzati.
  /// Per chiudere il socket globale, chiamare [ShspSocketSingleton.destroy]
  /// separatamente.
  @override
  void close() {
    super.close();
  }
}
