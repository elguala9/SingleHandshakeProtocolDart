import 'dart:io';

import '../../../shsp.dart';
/// Minimal lifecycle interface shared by [IShspSocket] and [IDualShspSocket].
///
/// Contains only the management methods needed by [BaseShspSocketSingleton]
/// and similar infrastructure, without implying a single-socket identity.
abstract interface class IShspSocketBase {
  InternetAddress? get localAddress;
  int? get localPort;
  ICompressionCodec get compressionCodec;
  bool get isClosed;
  ShspSocketProfile extractProfile();
  void applyProfile(ShspSocketProfile profile);
  void close();
  /// Send data to a remote address (as string) and port
  /// Returns the number of bytes written
  int sendTo(List<int> buffer, PeerInfo peer);
  
  /// Associates a callback with incoming messages from a specific remote endpoint
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb);

  /// Removes a message callback associated with a specific remote endpoint
  /// Returns true if a callback was removed, false if no callback was found
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb);
}
