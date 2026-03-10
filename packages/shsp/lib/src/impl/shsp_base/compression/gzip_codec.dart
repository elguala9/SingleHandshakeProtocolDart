import 'dart:io' show gzip;
import '../../../interfaces/connection/i_shsp_handshake.dart';
import '../../../interfaces/exceptions/shsp_exceptions.dart';
import '../../../interfaces/i_compression_codec.dart';
import '../../../interfaces/i_shsp_instance.dart';
import '../../../interfaces/i_shsp_instance_handler.dart';
import '../../../interfaces/i_shsp_peer.dart';
import '../../../interfaces/i_shsp_socket.dart';

/// GZip compression codec implementation
///
/// Fast and reliable compression with excellent compression ratio.
/// Recommended for bandwidth-constrained scenarios and general use.
///
/// Uses Dart's built-in dart:io gzip implementation.
/// - Speed: ⚡⚡ (moderate)
/// - Compression: 50-95% (excellent)
/// - CPU: Moderate
class GZipCodec implements ICompressionCodec {
  @override
  String get name => 'GZip';

  @override
  List<int> encode(List<int> data) {
    return gzip.encode(data);
  }

  @override
  List<int> decode(List<int> data) {
    return gzip.decode(data);
  }
}
