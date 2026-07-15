import 'dart:io';
import '../../interfaces/dual/i_dual_shsp_socket_auto.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/socket/i_shsp_socket.dart';
import '../../interfaces/wrapper/i_shsp_socket_wrapper.dart';
import '../../types/callback_types.dart';
import '../../types/peer_types.dart';
import '../../types/socket_profile.dart';
import '../../types/sockets.dart';

mixin DualShspSocketWrapperDelegationMixin implements IDualShspSocketAuto {
  IDualShspSocketAuto get delegateDualSocket;

  @override
  IShspSocket? get ipv4Socket => delegateDualSocket.ipv4Socket;

  @override
  IShspSocket? get ipv6Socket => delegateDualSocket.ipv6Socket;

  @override
  IShspSocket? get ipv4SocketImpl => delegateDualSocket.ipv4SocketImpl;

  @override
  set ipv4SocketImpl(IShspSocket? socket) =>
      delegateDualSocket.ipv4SocketImpl = socket;

  @override
  IShspSocket? get ipv6SocketImpl => delegateDualSocket.ipv6SocketImpl;

  @override
  set ipv6SocketImpl(IShspSocket? socket) =>
      delegateDualSocket.ipv6SocketImpl = socket;

  @override
  IShspSocket? get ipv4SocketForMessages =>
      delegateDualSocket.ipv4SocketForMessages;

  @override
  IShspSocket? get ipv6SocketForMessages =>
      delegateDualSocket.ipv6SocketForMessages;

  @override
  IShspSocket? get ipv4SocketForProfile =>
      delegateDualSocket.ipv4SocketForProfile;

  @override
  IShspSocket? get ipv6SocketForProfile =>
      delegateDualSocket.ipv6SocketForProfile;

  @override
  IShspSocketWrapper get ipv4SocketWrapper =>
      delegateDualSocket.ipv4SocketWrapper;

  @override
  IShspSocketWrapper get ipv6SocketWrapper =>
      delegateDualSocket.ipv6SocketWrapper;

  @override
  RawDatagramSocket get socket => delegateDualSocket.socket;

  @override
  void migrateSocketIpv4(IShspSocket socket) =>
      delegateDualSocket.migrateSocketIpv4(socket);

  @override
  void migrateSocketIpv6(IShspSocket socket) =>
      delegateDualSocket.migrateSocketIpv6(socket);

  @override
  IShspSocket refreshSocketIpv4() => delegateDualSocket.refreshSocketIpv4();

  @override
  IShspSocket refreshSocketIpv6() => delegateDualSocket.refreshSocketIpv6();

  @override
  Sockets refreshSockets() => delegateDualSocket.refreshSockets();

  @override
  void applyProfile(ShspSocketProfile profile) =>
      delegateDualSocket.applyProfile(profile);

  @override
  void close() => delegateDualSocket.close();

  @override
  ICompressionCodec get compressionCodec =>
      delegateDualSocket.compressionCodec;

  @override
  void destroy() => delegateDualSocket.destroy();

  @override
  ShspSocketProfile extractProfile() => delegateDualSocket.extractProfile();

  @override
  bool get isClosed => delegateDualSocket.isClosed;

  @override
  InternetAddress? get localAddress => delegateDualSocket.localAddress;

  @override
  int? get localPort => delegateDualSocket.localPort;

  @override
  CallbackOnWithSocket get onClose => delegateDualSocket.onClose;

  @override
  CallbackOnErrorWithSocket get onError => delegateDualSocket.onError;

  @override
  CallbackOnWithSocket get onListening => delegateDualSocket.onListening;

  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      delegateDualSocket.removeMessageCallback(peer, cb);

  @override
  int sendTo(List<int> buffer, PeerInfo peer) =>
      delegateDualSocket.sendTo(buffer, peer);

  @override
  String serializedObject() => delegateDualSocket.serializedObject();

  @override
  void setCloseCallback(void Function() cb) =>
      delegateDualSocket.setCloseCallback(cb);

  @override
  void setErrorCallback(void Function(dynamic err) cb) =>
      delegateDualSocket.setErrorCallback(cb);

  @override
  void setListeningCallback(void Function() cb) =>
      delegateDualSocket.setListeningCallback(cb);

  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      delegateDualSocket.setMessageCallback(peer, cb);
}
