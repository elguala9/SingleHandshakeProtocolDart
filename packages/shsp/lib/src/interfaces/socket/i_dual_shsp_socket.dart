import 'dart:io';

import '../../types/callback_types.dart';
import '../../types/peer_types.dart';
import '../../types/socket_profile.dart';
import '../i_compression_codec.dart';
import '../i_shsp_instance.dart' show CallbackOn, CallbackOnError;
import '../i_shsp_socket.dart';
import '../i_shsp_socket_base.dart';

/// Composite interface for dual IPv4/IPv6 socket routing.
///
/// A dual socket is NOT a single [IShspSocket] — it is a router that holds
/// two sockets and dispatches messages to the appropriate one based on the
/// peer's address family. It intentionally does not extend [IShspSocket].
abstract interface class IDualShspSocket implements IShspSocketBase {
  /// The underlying IPv4 socket
  IShspSocket get ipv4Socket;

  /// The underlying IPv6 socket, if available
  IShspSocket? get ipv6Socket;

  InternetAddress? get localAddress;
  int? get localPort;

  ICompressionCodec get compressionCodec;

  CallbackOn get onClose;
  CallbackOnError get onError;
  CallbackOn get onListening;

  void setListeningCallback(void Function() cb);
  void setCloseCallback(void Function() cb);
  void setErrorCallback(void Function(dynamic err) cb);

  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb);
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb);

  int sendTo(List<int> buffer, PeerInfo peer);

  bool get isClosed;

  ShspSocketProfile extractProfile();
  void applyProfile(ShspSocketProfile profile);

  String serializedObject();

  void close();
  void destroy();
}
