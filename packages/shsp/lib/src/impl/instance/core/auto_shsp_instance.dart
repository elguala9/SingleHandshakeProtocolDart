import 'dart:io';

import 'package:meta/meta.dart';
import '../../../interfaces/i_compression_codec.dart';
import '../../../interfaces/socket/i_shsp_socket.dart';
import '../../../interfaces/socket/i_shsp_socket_base.dart';
import '../../../types/peer_types.dart';

import '../../socket/core/shsp_socket_singleton.dart';
import '../../mixins/socket_change_listener_mixin.dart';
import 'shsp_instance.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// An [ShspInstance] that automatically uses the global [ShspSocketSingleton] socket.
///
/// ## Confronto con [ShspInstance]
/// - [ShspInstance]: richiede un [IShspSocket] esplicito come parametro
/// - [AutoShspInstance]: ottiene il socket automaticamente dal [ShspSocketSingleton]
///
/// Possono coesistere più istanze di [AutoShspInstance], ognuna per un remote peer
/// diverso, condividendo lo stesso socket globale sottostante.
///
/// ## Gestione delle riconnessioni
/// Quando il [ShspSocketSingleton] sostituisce il socket (via [ShspSocketSingleton.reconnect] o [ShspSocketSingleton.setSocket]),
/// [AutoShspInstance] automaticamente:
/// - Riceve notifica del nuovo socket
/// - Rimuove il callback dal vecchio socket
/// - Registra il callback con il nuovo socket
/// - Continua a ricevere messaggi senza interruzioni logiche
///
/// ## Esempio
/// ```dart
/// // Opzionale: inizializza il singleton prima (con parametri specifici)
/// await ShspSocketSingleton.getInstance(
///   address: InternetAddress.anyIPv4,
///   port: 9000,
/// );
///
/// // Crea instance senza passare il socket
/// final instance = await AutoShspInstance.create(
///   remotePeer: PeerInfo(address: remoteAddress, port: remotePort),
/// );
/// ```
@dependencyInjectable
class AutoShspInstance extends ShspInstance with SocketChangeListenerMixin {
  AutoShspInstance({
    required super.remotePeer,
    @Subkey.inherited() required super.socket,
    required super.keepAliveSeconds,
    ShspSocketSingleton? singleton,
  }) {
    if (singleton != null) {
      initSocketChangeListener(singleton);
    }
  }

  factory AutoShspInstance.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final remotePeer = RegistryManager.instance.getInstance<PeerInfo>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socket = RegistryManager.instance.getInstance<IShspSocketBase>(key: key, subkey: subkey); // GENERATED CODE - DO NOT MODIFY BY HAND
    final keepAliveSeconds = RegistryManager.instance.getInstance<int>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final singleton = RegistryManager.instance.getInstanceNullable<ShspSocketSingleton>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return AutoShspInstance( // GENERATED CODE - DO NOT MODIFY BY HAND
      remotePeer: remotePeer, // GENERATED CODE - DO NOT MODIFY BY HAND
      socket: socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      keepAliveSeconds: keepAliveSeconds, // GENERATED CODE - DO NOT MODIFY BY HAND
      singleton: singleton, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Factory solo per i test — consente di iniettare un socket esplicito.
  ///
  /// Usare questo constructor nelle suite di test di compliance (es. testIShspInstance)
  /// dove i test creano socket dedicati. Non usare in produzione.
  @visibleForTesting
  factory AutoShspInstance.withSocket({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    int keepAliveSeconds = 30,
  }) => AutoShspInstance(
    remotePeer: remotePeer,
    socket: socket,
    keepAliveSeconds: keepAliveSeconds,
  );

  /// Crea un [AutoShspInstance] per comunicare con [remotePeer].
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
  ///   - [keepAliveSeconds]: Secondi tra i keep-alive (default: 30)
  static Future<AutoShspInstance> create({
    required PeerInfo remotePeer,
    InternetAddress? address,
    int? port,
    ICompressionCodec? compressionCodec,
    int keepAliveSeconds = 30,
  }) async {
    final singleton = await ShspSocketSingleton.getInstance(
      address: address,
      port: port,
      compressionCodec: compressionCodec,
    );

    return AutoShspInstance(
      remotePeer: remotePeer,
      socket: singleton.socket,
      keepAliveSeconds: keepAliveSeconds,
      singleton: singleton,
    );
  }

  /// Chiude questa istanza (rimuove il suo callback dal socket condiviso e interrompe keep-alive).
  ///
  /// Il [ShspSocketSingleton] viene intenzionalmente lasciato aperto, così
  /// gli altri peer/instance che condividono lo stesso socket non sono influenzati.
  /// Per chiudere il socket globale, chiamare [ShspSocketSingleton.destroy]
  /// separatamente.
  @override
  void close() {
    deregisterSocketChangeListener();
    super.close();
  }
}
