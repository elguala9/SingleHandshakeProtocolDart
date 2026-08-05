import 'dart:io';

import 'package:meta/meta.dart';
import '../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

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
@dependencyInjectable
class AutoShspPeer extends ShspPeer with SocketChangeListenerMixin {
  AutoShspPeer({
    required super.remotePeer,
    @Subkey.inherited() required super.socket,
    super.messageCallback,
    ShspSocketSingleton? singleton,
  }) {
    if (singleton != null) {
      initSocketChangeListener(singleton);
    }
  }

  factory AutoShspPeer.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final remotePeer = RegistryManager.instance.getInstance<PeerInfo>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socket = RegistryManager.instance.getInstance<IShspSocketBase>(key: key, subkey: subkey); // GENERATED CODE - DO NOT MODIFY BY HAND
    final messageCallback = RegistryManager.instance.tryGetInstance<MessageCallback>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final singleton = RegistryManager.instance.tryGetInstance<ShspSocketSingleton>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return AutoShspPeer( // GENERATED CODE - DO NOT MODIFY BY HAND
      remotePeer: remotePeer, // GENERATED CODE - DO NOT MODIFY BY HAND
      socket: socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      messageCallback: messageCallback, // GENERATED CODE - DO NOT MODIFY BY HAND
      singleton: singleton, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Factory solo per i test — consente di iniettare un socket esplicito.
  ///
  /// Usare questo constructor nelle suite di test di compliance (es. testIShspPeer)
  /// dove i test creano socket dedicati. Non usare in produzione.
  @visibleForTesting
  factory AutoShspPeer.withSocket({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    MessageCallback? messageCallback,
  }) => AutoShspPeer(
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

    return AutoShspPeer(
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
    deregisterSocketChangeListener();
    super.close();
  }
}
