import 'dart:io' show gzip;
import '../../../interfaces/i_compression_codec.dart';

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
  List<int> encode(List<int> data) => gzip.encode(data);

  @override
  List<int> decode(List<int> data) => gzip.decode(data);
}
