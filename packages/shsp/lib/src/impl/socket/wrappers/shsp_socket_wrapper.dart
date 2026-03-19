import 'dart:io';
import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// SHSP SocketWrapper: agisce come un proxy per permettere il cambio del socket
/// sottostante senza dover aggiornare i riferimenti in ogni ShspPeer.
class ShspSocketWrapper implements IShspSocket, IValueForRegistry {
  ShspSocketWrapper(this._socket);

  // Rimosso 'final' per permettere il cambio del riferimento del socket
  IShspSocket _socket;

  // Setter per aggiornare il socket interno
  set internalSocket(ShspSocket newSocket) => _socket = newSocket;

  @override
  void applyProfile(ShspSocketProfile profile) => _socket.applyProfile(profile);

  @override
  void close() => _socket.close();

  @override
  ICompressionCodec get compressionCodec => _socket.compressionCodec;

  @override
  void destroy() => _socket.destroy();

  @override
  ShspSocketProfile extractProfile() => _socket.extractProfile();

  @override
  bool get isClosed => _socket.isClosed;

  @override
  InternetAddress? get localAddress => _socket.localAddress;

  @override
  int? get localPort => _socket.localPort;

  @override
  CallbackOn get onClose => _socket.onClose;

  @override
  CallbackOnError get onError => _socket.onError;

  @override
  CallbackOn get onListening => _socket.onListening;

  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      _socket.removeMessageCallback(peer, cb);

  @override
  int sendTo(List<int> buffer, PeerInfo peer) => _socket.sendTo(buffer, peer);

  @override
  String serializedObject() => _socket.serializedObject();

  @override
  void setCloseCallback(void Function() cb) => _socket.setCloseCallback(cb);

  @override
  void setErrorCallback(void Function(dynamic err) cb) =>
      _socket.setErrorCallback(cb);

  @override
  void setListeningCallback(void Function() cb) =>
      _socket.setListeningCallback(cb);

  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      _socket.setMessageCallback(peer, cb);

  @override
  RawDatagramSocket get socket => _socket.socket;
}
