import 'dart:io';

import '../types/socket_profile.dart';
import 'i_compression_codec.dart';

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
}
