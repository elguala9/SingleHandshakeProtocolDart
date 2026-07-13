import 'dart:io';
import 'package:meta/meta.dart';

import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Proxy for [IDualShspSocketAuto] that allows swapping the underlying socket
/// without updating all references.
@isSingleton
class DualShspSocketWrapper implements IDualShspSocketWrapper {
  DualShspSocketWrapper();

  DualShspSocketWrapper.emptyForDI();

  DualShspSocketWrapper.createFromSocket(this.dualSocket);

  @isInjected
  @protected
  late IDualShspSocketAuto dualSocket;

  set internalSocket(IDualShspSocketAuto newSocket) => dualSocket = newSocket;

  @override
  IShspSocket? get ipv4Socket => dualSocket.ipv4Socket;

  @override
  IShspSocket? get ipv6Socket => dualSocket.ipv6Socket;

  @override
  IShspSocket? get ipv4SocketImpl => dualSocket.ipv4SocketImpl;

  @override
  set ipv4SocketImpl(IShspSocket? socket) => dualSocket.ipv4SocketImpl = socket;

  @override
  IShspSocket? get ipv6SocketImpl => dualSocket.ipv6SocketImpl;

  @override
  set ipv6SocketImpl(IShspSocket? socket) => dualSocket.ipv6SocketImpl = socket;

  @override
  IShspSocket? get ipv4SocketForMessages => dualSocket.ipv4SocketForMessages;

  @override
  IShspSocket? get ipv6SocketForMessages => dualSocket.ipv6SocketForMessages;

  @override
  IShspSocket? get ipv4SocketForProfile => dualSocket.ipv4SocketForProfile;

  @override
  IShspSocket? get ipv6SocketForProfile => dualSocket.ipv6SocketForProfile;

  @override
  IShspSocketWrapper get ipv4SocketWrapper => dualSocket.ipv4SocketWrapper;

  @override
  IShspSocketWrapper get ipv6SocketWrapper => dualSocket.ipv6SocketWrapper;

  @override
  RawDatagramSocket get socket => dualSocket.socket;

  @override
  void migrateSocketIpv4(IShspSocket socket) => dualSocket.migrateSocketIpv4(socket);

  @override
  void migrateSocketIpv6(IShspSocket socket) => dualSocket.migrateSocketIpv6(socket);

  @override
  IShspSocket refreshSocketIpv4() => dualSocket.refreshSocketIpv4();

  @override
  IShspSocket refreshSocketIpv6() => dualSocket.refreshSocketIpv6();

  @override
  Sockets refreshSockets() => dualSocket.refreshSockets();

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
  CallbackOnWithSocket get onClose => dualSocket.onClose;

  @override
  CallbackOnErrorWithSocket get onError => dualSocket.onError;

  @override
  CallbackOnWithSocket get onListening => dualSocket.onListening;

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
