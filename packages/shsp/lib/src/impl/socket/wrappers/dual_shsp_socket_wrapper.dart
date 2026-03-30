import 'dart:io';
import 'package:meta/meta.dart';

import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Proxy for [IDualShspSocketMigratable] that allows swapping the underlying socket
/// without updating all references.
@isSingleton
class DualShspSocketWrapper implements IDualShspSocketWrapper {
  DualShspSocketWrapper();

  DualShspSocketWrapper.createFromSocket(this.dualSocket);

  @isInjected
  @protected
  late IDualShspSocketMigratable dualSocket;

  set internalSocket(IDualShspSocketMigratable newSocket) => dualSocket = newSocket;

  @override
  IShspSocket get ipv4Socket => dualSocket.ipv4Socket;

  @override
  IShspSocket? get ipv6Socket => dualSocket.ipv6Socket;

  @override
  void applyProfile(ShspSocketProfile profile) =>
      dualSocket.applyProfile(profile);

  @override
  void close() => dualSocket.close();

  @override
  ICompressionCodec get compressionCodec => dualSocket.compressionCodec;

  @override
  void destroy() => dualSocket.destroy();

  @override
  ShspSocketProfile extractProfile() => dualSocket.extractProfile();

  @override
  bool get isClosed => dualSocket.isClosed;

  @override
  InternetAddress? get localAddress => dualSocket.localAddress;

  @override
  int? get localPort => dualSocket.localPort;

  @override
  CallbackOn get onClose => dualSocket.onClose;

  @override
  CallbackOnError get onError => dualSocket.onError;

  @override
  CallbackOn get onListening => dualSocket.onListening;

  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      dualSocket.removeMessageCallback(peer, cb);

  @override
  int sendTo(List<int> buffer, PeerInfo peer) =>
      dualSocket.sendTo(buffer, peer);

  @override
  String serializedObject() => dualSocket.serializedObject();

  @override
  void setCloseCallback(void Function() cb) => dualSocket.setCloseCallback(cb);

  @override
  void setErrorCallback(void Function(dynamic err) cb) =>
      dualSocket.setErrorCallback(cb);

  @override
  void setListeningCallback(void Function() cb) =>
      dualSocket.setListeningCallback(cb);

  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      dualSocket.setMessageCallback(peer, cb);
}
