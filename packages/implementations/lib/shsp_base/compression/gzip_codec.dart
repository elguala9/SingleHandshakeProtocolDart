import 'dart:io' show gzip;
import 'package:shsp_interfaces/shsp_interfaces.dart';

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
